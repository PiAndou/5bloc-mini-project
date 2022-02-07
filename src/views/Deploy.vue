<template>
  <b-container fluid>
    <div>
      <!-- Description -->
      <p>
        Vous vous apprêtez à déployer un nouveau Smart Contract. Vous serez
        référencé comme responsable en charge de cette nouvelle élection.
        Veuillez définir les dates de début et de fin de cette dernière, ainsi
        que la liste des candidats qui la composent et la liste des votants
        autorisés à participer.
      </p>

      <!-- Dates Section -->
      <b-form
        @submit.prevent="deploy"
        v-if="stubAccounts.length && !deployedElectionContract"
      >
        <div class="form-content">
          <!-- Start Date -->
          <b-form-group
            id="input-group-1"
            label="Date de début :"
            label-for="input-1"
          >
            <b-form-datepicker
              id="input-1"
              value-as-date
              v-model="form.startDate"
              class="mb-2"
              required
            ></b-form-datepicker>
          </b-form-group>

          <!-- End Date -->
          <b-form-group
            id="input-group-2"
            label="Date de fin :"
            label-for="input-2"
          >
            <b-form-datepicker
              id="input-2"
              value-as-date
              v-model="form.endDate"
              class="mb-2"
              required
            ></b-form-datepicker>
          </b-form-group>
        </div>

        <!-- Lists Section -->
        <div class="form-content">
          <!-- Candidates' list -->
          <b-form-group label="Liste des candidats :">
            <b-list-group>
              <b-list-group-item
                v-for="candidate in candidates"
                :key="candidate"
                >{{ candidate }}</b-list-group-item
              >
            </b-list-group>

            <b-form-input
              v-model="candidateAddr"
              placeholder="Entrer une adresse"
            ></b-form-input>
            <b-button
              class="list-button"
              :disabled="
                candidates.includes(candidateAddr) || candidateAddr === ''
              "
              @click="addCandidate()"
              >Ajouter</b-button
            >
          </b-form-group>

          <!-- Voters' list -->
          <b-form-group label="Liste des votants :">
            <b-list-group>
              <b-list-group-item v-for="voter in voters" :key="voter">{{
                voter
              }}</b-list-group-item>
            </b-list-group>

            <b-form-input
              v-model="voterAddr"
              placeholder="Entrer une adresse"
            ></b-form-input>
            <b-button
              class="list-button"
              :disabled="voters.includes(voterAddr) || voterAddr === ''"
              @click="addVoter()"
              >Ajouter</b-button
            >
          </b-form-group>
        </div>

        <!-- Deploy button -->
        <div class="button-deploy">
          <b-button type="submit" variant="primary">Déployer</b-button>
        </div>
      </b-form>

      <!-- left for debug to be removed in future -->
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
    const web3Provider = new Web3.providers.HttpProvider(
      "http://172.25.0.102:8545"
      //"http://192.168.12.146:8545"
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
      this.web3Instance!.eth.personal.unlockAccount(address, password, 15000);
      this.stubAccounts.push({
        address,
        password,
      });
    }

    console.log("stubAccounts", this.stubAccounts);
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