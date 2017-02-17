FROM apline/latest

ARG GIT_COMMIT
ARG VERSION
LABEL REPO="https://github.com/jimbydamonk/admintest"
LABEL GIT_COMMIT=$GIT_COMMIT
LABEL VERSION=$VERSION

# Because of https://github.com/docker/docker/issues/14914
ENV PATH=$PATH:/opt/admintest/bin

WORKDIR /opt/admintest/bin

COPY bin/admintest /opt/admintest/bin/
RUN chmod +x /opt/admintest/bin/admintest

CMD /opt/admintest/bin/admintest