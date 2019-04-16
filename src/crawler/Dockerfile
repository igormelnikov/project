FROM python:3.6-alpine

ENV APPHOME /app/search_engine_crawler/

COPY requirements.txt "$APPHOME"
RUN pip install -r "$APPHOME/requirements.txt"

WORKDIR $APPHOME
COPY . $APPHOME

CMD ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]
