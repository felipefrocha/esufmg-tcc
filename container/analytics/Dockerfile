FROM python:3
WORKDIR /app

RUN \
    groupadd -r executor && useradd -r executor -g executor \
    && chown -R executor:executor /app \
    &&  apt-get update \
    && apt-get full-upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        make \
        gcc \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

COPY --chown=executor:executor requirements.txt .

RUN pip install -r requirements.txt

ENV AWS_ACCESS_KEY_ID=AKIARBH4BMKZMHIAYPLQ
ENV AWS_SECRET_ACCESS_KEY=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
ENV S3_BUCKET='bancodoutorado'

COPY --chown=executor:executor . .

ENTRYPOINT [ "python3" ]
CMD [ "__init__.py" ]
