FROM python:3.6

ENV APPHOME /search_engine_ui
ENV FLASK_APP ui.py

RUN git clone https://github.com/express42/search_engine_ui.git && \
    pip install -r "$APPHOME/requirements.txt"

WORKDIR "$APPHOME/ui"

ENV MONGO mongo
ENV MONGO_PORT 27017

CMD ["gunicorn", "ui:app", "-b", "0.0.0.0"]
