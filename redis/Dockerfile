FROM python:3.8

LABEL maintainer="Hossam Hammady <hossam@rayyan.ai>"

WORKDIR /home

# install deps first
COPY requirements.txt /home/
RUN pip install -r requirements.txt

# copy rest of files
COPY /redis_migration.py /home/

ENTRYPOINT ["python", "redis_migration.py"]
