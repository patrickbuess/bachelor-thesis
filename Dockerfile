FROM python:3.7
ENV REFRESHED_AT "28-05-2021"

ENV PYTHONUNBUFFERED 1

RUN apt-get update -y && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip

WORKDIR /app
COPY requirements.txt requirements.txt
RUN python -m pip install -r requirements.txt
# ENTRYPOINT ["/app/entrypoint.sh"]
