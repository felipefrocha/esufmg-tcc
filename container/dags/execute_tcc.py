from datetime import datetime

import os
import logging
import re
from typing import Callable
import signal
import sys
import traceback
import pandas as pd
from pandas import DataFrame as df
from pathlib2 import Path
import psycopg2
from sqlalchemy import create_engine
import numpy as np
from scipy.stats import kendalltau

from airflow import DAG, XComArg
from airflow.models import Variable
from airflow.configuration import conf
from airflow.decorators import task, dag
from airflow.utils.dates import days_ago
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator


log = logging.getLogger(__name__)

worker_container_repository = conf.get('kubernetes', 'worker_container_repository')
worker_container_tag = conf.get('kubernetes', 'worker_container_tag')

try:
    from kubernetes.client import models as k8s
except ImportError:
    log.warning(
        "The example_kubernetes_executor example DAG requires the kubernetes provider."
        " Please install it with: pip install apache-airflow[cncf.kubernetes]"
    )
    k8s = None

S3_BUCKET = os.environ["S3_BUCKET"]
ATIVOS = {'AZITROMICINA': 1, 'AZITROMICINA DI-HIDRATADA': 2}

UFS = {
    'AC': 1,
    'AL': 2,
    'AM': 3,
    'AP': 4,
    'BA': 5,
    'CE': 6,
    'DF': 7,
    'ES': 8,
    'GO': 9,
    'MA': 10,
    'MG': 11,
    'MS': 12,
    'MT': 13,
    'PA': 14,
    'PB': 15,
    'PE': 16,
    'PI': 17,
    'PR': 18,
    'RJ': 19,
    'RN': 20,
    'RO': 21,
    'RR': 22,
    'RS': 23,
    'SC': 24,
    'SE': 25,
    'SP': 26,
    'TO': 27
}

default_args = {
    'owner': 'Felipe Rocha',
    'depends_on_past': False,
    'start_date': days_ago(0),
    'email': ['feliperocha@ufmg.br'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
}

resource_config = {
    "testes": {},
    "analytics": {
        "pod_override": k8s.V1Pod(
            spec=k8s.V1PodSpec(
                containers=[
                    k8s.V1Container(
                        name="base",
                        resources=k8s.V1ResourceRequirements(
                            requests={
                                'cpu': "250m",
                                'memory': "512Mi"
                            },
                            limits={
                                'cpu': "512m",
                                'memory': "2Gi"
                            }
                        ),
                    ),
                ],
            ),
        ),
    }
}


@dag(dag_id='azitromicina_consumption',
     schedule_interval=None,
     tags=['analytics', 'tcc', '2022', 'dcc'],
     default_args=default_args)
def azitromicina_consuption():

    files = S3ListOperator(
        task_id="get_input",
        bucket=S3_BUCKET,
        prefix='extended/EDA_Industrializados_20201',
    )

    @task(task_id='process_data_sets', executor_config=resource_config["analytics"])
    def run_process(aws_conn_id, bucket, file):

        hook = S3Hook(aws_conn_id=aws_conn_id)
        file_name = f'/tmp/{file}'
        dirname = os.path.dirname(os.path.abspath(file_name))
        date_executed = re.search("(20[0-9]{,})", file_name).group()

        log.info(file_name, dirname, date_executed)

        if not os.path.isdir(dirname):
            Path(dirname).mkdir(parents=True, exist_ok=True)

        hook.download_file(key=file, bucket_name=bucket, local_path='/tmp/')

        df_result = None

        try:
            with open(file=file_name, mode='r', encoding='ISO-8859-1') as csv_file:
                df = pd.read_csv(csv_file, iterator=True,
                                 chunksize=5000, low_memory=True, delimiter=';')

                df_result = pd.concat([chunk[chunk["PRINCIPIO_ATIVO"].str.contains(
                    "AZITROMICINA", na=False)] for chunk in df])

            df_qtd = df_result[["ANO_VENDA", "MES_VENDA",
                                "UF_VENDA", "QTD_VENDIDA"]].dropna()

            tau = kendalltau(df_qtd["UF_VENDA"].replace(
                UFS), df_result["QTD_VENDIDA"])

            df_tau = pd.DataFrame(
                {"date": date_executed, "correlation": tau[0], "pvalue": tau[1]})

            df_sum = df_qtd.groupby(
                ["ANO_VENDA", "MES_VENDA", "UF_VENDA"]).sum()

            conn_string = f'postgresql+psycopg2://postgres:N3w4dm1nS@postgres.default.svc.cluster.local:5432/tccanalytics'

            with create_engine(conn_string, pool_size=5, max_overflow=10) as conn:
                df_result.to_sql("azitromicina_consuption", conn, if_exists="append",
                                 index=False, chunksize=1000, method="multi")
                df_tau.to_sql("correlation_per_month", conn, if_exists="append",
                              index=False, chunksize=1000, method="multi")
                df_result.to_sql("summary", conn, if_exists="append",
                                 index=False, chunksize=1000, method="multi")

            return f'{date_executed} - {tau}'

        except Exception as ex:
            print(f'ERROR - processing {date_executed}:\n{ex} ')
            raise Exception("General error processing files")

    @task
    def resume(lines):
        output = "".join([f'{line}\n' for line in lines])
        print(output)
        return output

    outputs = run_process.partial(aws_conn_id="aws_default", bucket=files.bucket).expand(
        file=XComArg(files)
    )

    resume(lines=outputs)

if k8s:
    dag = azitromicina_consuption()