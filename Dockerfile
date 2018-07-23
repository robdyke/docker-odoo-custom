FROM odoo:11.0
MAINTAINER OpusVL <community@opusvl.com>

USER root

# Install some more fonts and locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        unzip \
        locales-all \
        locales \
        gnupg \
    && rm -rf /var/lib/apt/lists/*


# Install postgresql 10.0 client
ENV PG_MAJOR 10
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            postgresql-client-10

# Install barcode font
COPY pfbfer.zip /root/pfbfer.zip
RUN mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip /root/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

RUN mkdir /mnt/extra-addons-bundles && chmod -R 755 /mnt/extra-addons-bundles

COPY ./odoo.conf /etc/odoo/

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY opusvl-entrypoint.py /
RUN chmod a+rx /opusvl-entrypoint.py
ENTRYPOINT ["/opusvl-entrypoint.py"]

USER odoo

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN pip3 install -r /root/requirements.txt
ONBUILD USER odoo
