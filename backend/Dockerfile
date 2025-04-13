FROM perl:latest

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN cpanm --installdeps .

CMD ["perl", "./app.pl"]