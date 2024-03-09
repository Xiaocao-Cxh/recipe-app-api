FROM python:3.9-alpine3.13
# python is the base image, 3.9-alpine3.13 is the tag, and alpine is a lightweight linux distribution
LABEL maintainer="caoxuhang.com"
# metadata

ENV PYTHONUNBUFFERED 1
# environment variable, 1 means true and 0 means false
# 1 allows python to run in unbuffered mode, meaning it doesn't buffer the outputs but prints them directly

COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
WORKDIR /app
EXPOSE 8000

ARG DEV=false
RUN python -m venv /py && \
# create a virtual environment in /py in case of conflicts in any dependencies
    /py/bin/pip install --upgrade pip && \
    # upgrade pip in the virtual environment
    apk add --update --no-cache postgresql-client && \
    # client package needed to install inside alpine image for psycopg2 to be connected to postgresql
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    # install all the dependencies in the virtual environment
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt; \
    fi && \
    # shell script to install the dev dependencies if the argument DEV is true
    rm -rf /tmp && \
    # remove the temporary directory to avoid extra dependencies on image
    # keep the image as lightweight as possible
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user
# add a user called django-user, with no password, no home directory, and no login shell
# It is the best practice to run the container as a non-root user
# because if the container is compromised, the attacker will not have root access to the host machine

ENV PATH="/py/bin:$PATH"
# Update the PATH environment variable to include the virtual environment's binary directory

USER django-user
# switch to the django-user