FROM ubuntu:22.04
RUN apt update
RUN apt install -y wget
RUN wget https://ftp.orca.med.or.jp/pub/ubuntu/archive.key -O /etc/apt/keyrings/jma.asc
RUN wget https://ftp.orca.med.or.jp/pub/ubuntu/jma-receipt-weborca-jammy10.list \
    && mv jma-receipt-weborca-jammy10.list /etc/apt/sources.list.d/
RUN apt update
RUN apt dist-upgrade -y

# Preconfigure tzdata (for timezone selection) to avoid prompts during installation
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone && \
    apt update && \
    apt install -y tzdata

# Set non-interactive frontend to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive
RUN apt install -y jma-receipt-weborca
RUN weborca-install
RUN apt install vim -y

COPY db.conf.sh /opt/jma/weborca/conf/db.conf

# RUN /opt/jma/weborca/app/bin/jma-setup
# RUN systemctl restart jma-receipt-weborca

CMD ["sleep", "infinity"]
