FROM jenkins
USER root
RUN cd /usr/bin && wget "https://cli.run.pivotal.io/stable?version=6.17.1&release=linux64-binary" -O - | tar zxvf - && chmod 755 cf
RUN mkdir /home/jenkins
COPY OTCPlugin /home/jenkins
RUN cd /home/jenkins && chmod 755 OTCPlugin

COPY jobs /home/jenkins/jobs
COPY init_jobs.sh /home/jenkins/
RUN chmod 755 /home/jenkins/init_jobs.sh
RUN chown -R jenkins /home/jenkins && chgrp -R staff /home/jenkins

USER jenkins
ENV CF_HOME=/home/jenkins
ENV CF_PLUGIN_HOME=/home/jenkins
RUN cf install-plugin -f /home/jenkins/OTCPlugin

CMD /home/jenkins/init_jobs.sh
