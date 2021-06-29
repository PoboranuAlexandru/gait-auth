FROM python:3.9
WORKDIR /auth
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY auth.py .
COPY database.py .
EXPOSE 5000
CMD [ "python", "auth.py" ]