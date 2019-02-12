FROM python:3.6

ENV APPHOME /search_engine_crawler
ENV EXCLUDE_URLS '.*github.com'

RUN git clone https://github.com/express42/search_engine_crawler.git && \
    pip install -r "$APPHOME/requirements.txt"

WORKDIR $APPHOME

ENV MONGO mongo
ENV MONGO_PORT 27017
ENV RMQ_HOST rabbit

ENV RMQ_USERNAME guest
ENV RMQ_PASSWORD guest

CMD ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]
