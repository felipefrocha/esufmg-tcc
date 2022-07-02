import os
from typing import Callable, Tuple
import boto3
import logging
from botocore.exceptions import ClientError
from concurrent.futures import ProcessPoolExecutor
import signal
import sys
import traceback
import pandas as pd
from pandas import DataFrame as df
from pathlib2 import Path
import numpy as np
from scipy.stats import kendalltau

###
# Configure logs
###
log = logging.getLogger(__name__)
log.setLevel(getattr(logging, 'DEBUG'))
FORMAT = '%(asctime)s - %(name)s - %(processName)10s - %(threadName)10s - %(funcName)s - %(levelname)s - %(message)s'
logging.basicConfig(format=FORMAT)
###
# END - Configure logs
###




S3_BUCKET = os.environ["S3_BUCKET"]

ATIVOS = {'AZITROMICINA':1, 'AZITROMICINA DI-HIDRATADA': 2}

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


def general_error(excp, code=137):
    exc_type, exc_value, exc_traceback = sys.exc_info()
    log.error(excp)
    traceback.print_tb(exc_traceback, limit=1, file=sys.stdout)
    exit(code)


def filter_file(file_name: str) -> None:
    mode = 'w' if not os.path.isfile(file_name) else 'a'
    dirname = os.path.dirname(
        f'{file_name}')

    df_result = None

    if not os.path.isdir(dirname):
        Path(dirname).mkdir(parents=True, exist_ok=True)

    try:
        with open(file=file_name, mode='r', encoding='ISO-8859-1') as csv_file:
            df = pd.read_csv(csv_file, iterator=True,
                             chunksize=5000, low_memory=True, delimiter=';')

            df_result = pd.concat([chunk[chunk["PRINCIPIO_ATIVO"].str.contains(
                "AZITROMICINA", na=False)] for chunk in df])
            df_qtd = df_result[["ANO_VENDA","MES_VENDA","UF_VENDA","PRINCIPIO_ATIVO","QTD_VENDIDA"]].dropna()
            df_tau = kendalltau(df_result[["UF_VENDA"]].replace(UFS),df_result["PRINCIPIO_ATIVO"])
            print(df_qtd.groupby(["ANO_VENDA","MES_VENDA","UF_VENDA","PRINCIPIO_ATIVO"]).sum())
            print(df_tau)
    except Exception as ex:
        log.error(ex)
        raise Exception("General error processing files")

    # Cria/abre o arquivo para gravação
    # with open(file=f'{file_name}page{page}.csv', mode=mode, newline='') as csv_file:
    #     log.info(f'Page: {page}')
    #     df.to_csv(path_or_buf=csv_file, index=False, quotechar='"', encoding='utf8', sep=';')
    #     log.info("FINISH")



############################################################

def run_routine(data: Tuple[str, Callable]):
    data, routine = data
    log.info(f'executing {data}')
    routine(data)
    log.info(f'{data} Requests finished')


def analyse_files():
    file_names = [(f'/files/{dir}/{file}', filter_file)
                  for dir in os.listdir('/files') for file in os.listdir(f'/files/{dir}') if file.endswith(".csv")]#[:1]

    log.info('Analysing Files')

    try:
        with ProcessPoolExecutor(max_workers=8) as executor:
            list(zip(file_names, executor.map(run_routine, file_names)))
    except KeyboardInterrupt:
        general_error(Exception('Interrupt'), 137)
    except Exception as ex:
        general_error(ex)
#############################################################




def main():
    log.info("Application starting")
    analyse_files()
    log.info("Finishing Routine")


if __name__ == '__main__':
    original_sigint_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGINT, original_sigint_handler)

    try:
        main()
    except KeyboardInterrupt:
        general_error(Exception('Interrupt'), 0)
    except SystemError as ex:
        log.info("Something not right happen, exiting now")
        general_error(ex)
    except Exception as es:
        log.error("WTF...!!!")
        general_error(es)
