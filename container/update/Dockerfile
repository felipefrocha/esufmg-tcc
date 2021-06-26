FROM python:3-alpine
WORKDIR /app

RUN \
 addgroup -S executor && adduser -S executor -G executor \
 && chown -R executor:executor /app

COPY --chown=executor:executor requirements.txt .
RUN pip install -r requirements.txt

ENV AWS_ACCESS_KEY_ID=AKIARBH4BMKZMHIAYPLQ
ENV AWS_SECRET_ACCESS_KEY=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
ENV S3_BUCKET='bancodoutorado'

COPY --chown=executor:executor . .

ENTRYPOINT [ "python3" ]
CMD [ "__init__.py" ]
