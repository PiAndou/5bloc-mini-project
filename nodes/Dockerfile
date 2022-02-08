FROM ethereum/client-go

ARG ACCOUNT_PASSWORD

COPY genesis.json /tmp
#COPY private-key.txt /tmp
RUN geth init /tmp/genesis.json \
    && rm -f ~/.ethereum/geth/nodekey \
    && echo ${ACCOUNT_PASSWORD} > /tmp/password \
    && geth account new --password /tmp/password \
    #&& geth account import --password /tmp/password /tmp/private-key.txt \
    && rm -f /tmp/password

ENTRYPOINT ["geth"]