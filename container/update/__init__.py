import os
from typing import Callable, Tuple
import boto3
import logging
from botocore.exceptions import ClientError
from concurrent.futures import ProcessPoolExecutor
import sys
import traceback

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


def upload_file(request: Tuple[str, str, str]):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """
    file_name, bucket, object_name = request

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_name)

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        log.error(e)
        return False
    return True


def general_error(excp, code=137):
    exc_type, exc_value, exc_traceback = sys.exc_info()
    log.error(excp)
    traceback.print_tb(exc_traceback, limit=1, file=sys.stdout)
    exit(code)


def run_routine(data: Tuple[Tuple[str, str, str], Callable]):
    data, routine = data
    log.info(f'executing {data}')
    routine(data)
    log.info(f'{data} Requests finished')


def upload_files_s3():
    file_names = [((f'/files/{dir}/{file}', f'{S3_BUCKET}', f'extended/{file}'), upload_file)
                  for dir in os.listdir('/files') for file in os.listdir(f'/files/{dir}') if file.endswith(".csv")]

    log.info('Sending files to S3')

    try:
        with ProcessPoolExecutor(max_workers=8) as executor:
            list(zip(file_names, executor.map(run_routine, file_names)))
    except KeyboardInterrupt:
        general_error(Exception('Interrupt'), 137)
    except Exception as ex:
        general_error(ex)


def download_files():
    s3 = boto3.resource('s3')
    response = s3.meta.client.list_objects_v2(
        Bucket=S3_BUCKET,
        Prefix="filterd"
    )
    print(response)

    objects = list(map(lambda x: x["Key"], response["Contents"]))
    print(len(objects))

    for object in objects:
        filename = object.split('/')[1]
        s3.meta.client.download_file(S3_BUCKET, object, f'/tmp/{filename}')
        print(object)


upload_files_s3()
