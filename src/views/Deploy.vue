<template>
  <b-container fluid class="fillspace box red">
    <div>
      <b-form
        @submit.prevent="deploy"
        v-if="stubAccounts.length && !deployedElectionContract"
      >
        <b-form-group
          id="input-group-1"
          label="Start date:"
          label-for="input-1"
          description="The start date of the contract"
        >
          <b-form-datepicker
            id="input-1"
            value-as-date
            v-model="form.startDate"
            class="mb-2"
            required
          ></b-form-datepicker>
        </b-form-group>

        <b-form-group
          id="input-group-2"
          label="End date:"
          label-for="input-2"
          description="The end date of the contract"
        >
          <b-form-datepicker
            id="input-2"
            value-as-date
            v-model="form.endDate"
            class="mb-2"
            required
          ></b-form-datepicker>
        </b-form-group>

        <b-form-group
          label="Candidates:"
          description="The candidates to the election"
        >
          <b-list-group>
            <b-list-group-item
              v-for="candidate in candidates"
              :key="candidate"
              >{{ candidate }}</b-list-group-item
            >
          </b-list-group>

          <b-form-input
            v-model="candidateAddr"
            placeholder="Enter address"
          ></b-form-input>
          <b-button
            :disabled="
              candidates.includes(candidateAddr) || candidateAddr === ''
            "
            @click="addCandidate()"
            >Add candidate</b-button
          >
        </b-form-group>

        <b-form-group label="Voters:" description="The voters of the election">
          <b-list-group>
            <b-list-group-item v-for="voter in voters" :key="voter">{{
              voter
            }}</b-list-group-item>
          </b-list-group>

          <b-form-input
            v-model="voterAddr"
            placeholder="Enter address"
          ></b-form-input>
          <b-button
            :disabled="voters.includes(voterAddr) || voterAddr === ''"
            @click="addVoter()"
            >Add voter</b-button
          >
        </b-form-group>

        <b-button type="submit" variant="primary">Deploy</b-button>
      </b-form>
      <b-card class="mt-3" header="Form Data Result">
        <pre class="m-0">{{ form }}</pre>
      </b-card>

      <b-card
        class="mt-3"
        header="Contract address"
        v-if="deployedElectionContract"
      >
        <pre class="m-0">{{ deployedElectionContract._address }}</pre>
      </b-card>
    </div>

    <button @click="generateStubAccounts" v-if="!stubAccounts.length">
      Generate stub accounts
    </button>
    <table v-if="stubAccounts.length">
      <thead>
        <tr>
          <th>Address</th>
          <th>Password</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="account in stubAccounts" :key="account.address">
          <td>{{ account.address }}</td>
          <td>{{ account.password }}</td>
          <td>
            <button @click="currentAddress = account.address">
              Make default
            </button>
            <button @click="unlockAccount(account.address, account.password)">
              Unlock
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </b-container>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import ElectionContract from "@/../build/contracts/ElectionContract.json";
import Web3 from "web3";

@Component({
  components: {
    // HelloWorld,
  },
})
export default class Deploy extends Vue {
  web3Instance: Web3 | null = null;
  currentAddress: string | null = null;
  electionContract: any = null;
  deployedElectionContract: any = null;
  candidates: any[] = [];
  voters: any[] = [];
  candidateAddr = "";
  voterAddr = "";
  stubAccounts: any = [];

  form: any = {
    startDate: null,
    endDate: null,
  };

  async mounted() {
    const web3Provider = new Web3.providers.WebsocketProvider(
      "ws://172.25.0.102:8546"
    );

    if (typeof (window as any).ethereum !== "undefined") {
      console.log("MetaMask is installed!");

      // (window as any).ethereum.request({ method: 'eth_requestAccounts' });

      // this.web3Instance = new Web3((window as any).ethereum);
      this.web3Instance = new Web3(web3Provider);

      console.log("web3Instance", this.web3Instance);

      const fetchedAccounts = await this.web3Instance.eth.getAccounts();

      console.log("fetchedAccounts", fetchedAccounts);

      this.currentAddress = fetchedAccounts[0];

      this.electionContract = new this.web3Instance.eth.Contract(
        ElectionContract.abi as any
        // ElectionContract.networks['5777'].address
      ) as any;

      console.log("electionContract", this.electionContract);
    } else {
      console.log("MetaMask is not installed");
    }
  }

  beforeDestroy() {
    if (this.web3Instance) {
      this.web3Instance = null;
    }

    if (this.electionContract) {
      this.electionContract = null;
    }
  }

  async generateStubAccounts() {
    for (const i of new Array(6)) {
      const password = (Math.random() + 1).toString(36).substring(7);

      const address = await this.web3Instance!.eth.personal.newAccount(
        password
      );

      this.stubAccounts.push({
        address,
        password,
      });
    }

    console.log("stubAccounts", this.stubAccounts);
  }

  async unlockAccount(address: string, password: string) {
    // unlock for a long time
    this.web3Instance!.eth.personal.unlockAccount(address, password, 15000);
  }

  async deploy() {
    // const contractByteCode = await this.web3Instance!.eth.getCode(
    //   ElectionContract.networks['5777'].address
    // );
    const contractByteCode = ElectionContract.bytecode;

    // const candidates: string[] = this.stubAccounts
    //   .filter((account: any) => !account.address !== this.currentAddress)
    //   // .slice(0, 10)
    //   .map((account: any) => account.address);
    // const voters: string[] = this.stubAccounts
    //   .filter((account: any) => !account.address !== this.currentAddress)
    //   .map((account: any) => account.address)
    //   .filter((addr: string) => !candidates.includes(addr));

    const candidates = this.candidates;
    const voters = this.voters;

    const startDate = Math.trunc(this.form.startDate.getTime() / 1000);
    const endDate = Math.trunc(this.form.endDate.getTime() / 1000);

    console.log("startDate", startDate);
    console.log("endDate", endDate);

    this.deployedElectionContract = await this.electionContract
      .deploy({
        data: contractByteCode,
        arguments: [candidates, voters, startDate, endDate],
      })
      .send({
        from: this.currentAddress,
        gas: 2120541,
        gasPrice: "2000000000",
      });

    console.log("deployedElectionContract", this.deployedElectionContract);
  }

  addCandidate() {
    if (this.candidateAddr.trim()) {
      this.candidates.push(this.candidateAddr.trim());

      this.candidateAddr = "";
    }
  }

  addVoter() {
    if (this.voterAddr.trim()) {
      this.voters.push(this.voterAddr.trim());

      this.voterAddr = "";
    }
  }
}
</script>
