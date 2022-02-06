const ElectionContract = artifacts.require("../contracts/ElectionContract.sol");

module.exports = function (deployer) {
  const stubAccounts = [
    {
        "address": "0xea4714aeD29dcbdBcC0920ab32B51C49F1714ba9",
        "password": "164we"
    },
    {
        "address": "0x4DA5Afb5ad265ACdC2d5f16A723ed0d1113e3C4E",
        "password": "mwjxm"
    },
    {
        "address": "0x819BCf6dE2f8eB7E3a77E9E90c97959E2FEBfaef",
        "password": "u9uv6"
    },
    {
        "address": "0x4F439A1273749DC65b745621FaCc537fA92624B8",
        "password": "c7k51"
    },
    {
        "address": "0xc55F741E2DfebEc04aa0075B168fE310567F8d67",
        "password": "jrw62"
    },
    {
        "address": "0xd791b49D6EB86913F9203980884ED71a064ACdEb",
        "password": "3yl64"
    }
  ];
  const currentAdress = stubAccounts[0].address;

  const candidates = stubAccounts
    .filter((account) => !account.address !== currentAdress)
    .slice(0, 10)
    .map((account) => account.address);
  const voters = stubAccounts
    .filter((account) => !account.address !== currentAdress)
    .map((account) => account.address)
    .filter((addr) => !candidates.includes(addr));

  // Start now
  const startDate = Math.trunc(new Date().getTime() / 1000);
  // End in 5 days
  const endDate = Math.trunc(
    new Date(new Date().getTime() + 5 * 24 * 60 * 60 * 1000).getTime() / 1000
  );

  deployer.deploy(ElectionContract, candidates, voters, startDate, endDate);
};
