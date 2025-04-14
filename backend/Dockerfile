FROM perl:latest

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN cpanm --installdeps .

ONBUILD CMD ["perl", "./migratios/migrate.pl"]

CMD ["perl", "./app.pl"]