FROM python:3.6-alpine

ENV APPHOME /app/search_engine_ui/

ENV FLASK_APP ui.py

COPY requirements.txt "$APPHOME"
RUN pip install -r "$APPHOME/requirements.txt"

WORKDIR "$APPHOME/ui"
COPY . $APPHOME

CMD ["gunicorn", "ui:app", "-b", "0.0.0.0"]
