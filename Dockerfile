FROM rocker/shiny:latest

# Working directory
WORKDIR /srv/shiny-server/app

# Install system dependencies for RPostgres
RUN apt-get update && apt-get install -y \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    libharfbuzz-dev libfribidi-dev libfontconfig1-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy app files
COPY . /srv/shiny-server/app

# Install R packages
RUN R -e "install.packages(c('shiny','shinydashboard','DBI','RPostgres','tidyverse','plotly','DT','viridis'), repos='https://cloud.r-project.org')"

# Permissions
RUN chown -R shiny:shiny /srv/shiny-server/app

# Expose port
EXPOSE 3838

# Launch Shiny Server
CMD ["shiny-server"]
