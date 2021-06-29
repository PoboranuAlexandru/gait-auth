FROM python:3.9
WORKDIR /prediction
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY prediction.py .
COPY XGBClassifier.json .
EXPOSE 5000
CMD [ "python", "prediction.py" ]