FROM ubuntu:noble

# Update our main system

RUN apt-get update
RUN apt-get dist-upgrade -y

# Get some dependencies for adding apt repositories

RUN apt-get install -y wget gnupg pwgen

# Add perforce repo

RUN wget -qO - https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /usr/share/keyrings/perforce.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/perforce.gpg] http://package.perforce.com/apt/ubuntu noble release' > /etc/apt/sources.list.d/perforce.list
RUN apt-get update

# Actually install it

RUN apt-get install -y helix-p4d

# Install Python 3

RUN apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv

# Clean up apt cache
RUN rm -rf /var/lib/apt/lists/*

# Copy p4d.template to a safe place
RUN mkdir -p /opt/perforce/
RUN cp /etc/perforce/p4dctl.conf.d/p4d.template /opt/perforce/p4d.template

# Add our start script
COPY ./perforce.sh /opt/perforce/perforce.sh
RUN chmod a+x /opt/perforce/perforce.sh

# Start the server
CMD /opt/perforce/perforce.sh
