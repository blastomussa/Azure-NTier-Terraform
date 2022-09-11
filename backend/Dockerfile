# Import python:3.8 slim docker image
FROM python:3.8-slim-bullseye

# Install git
RUN apt-get -y update
RUN apt-get -y install git

# Clone github repository
RUN git clone https://github.com/blastomussa/Azure-Terraform-F22.git /AzureProject/
WORKDIR /AzureProject/backend

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the required port
EXPOSE 80

CMD [ "python3", "./app.py" ]
