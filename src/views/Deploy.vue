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
      <b-form @submit.prevent="deploy" v-if="!deployedElectionContract">
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
              :min="new Date()"
              :max="form.endDate"
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
              :min="form.startDate"
              :disabled="!form.startDate"
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
    </div>
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

  form: any = {
    startDate: null,
    endDate: null,
  };

  async mounted() {
    if (typeof (window as any).ethereum !== "undefined") {
      (window as any).ethereum.request({ method: "eth_requestAccounts" });

      this.web3Instance = new Web3((window as any).ethereum);

      // recupere les comptes
      const fetchedAccounts = await this.web3Instance.eth.getAccounts();

      // le premier compte est le compte courant connecter via metamask
      this.currentAddress = fetchedAccounts[0];

      this.electionContract = new this.web3Instance.eth.Contract(
        ElectionContract.abi as any
      ) as any;

      // actualise le compte courant de metamask quand il change de compte
      (window as any).ethereum.on("accountsChanged", async () => {
        if (this.web3Instance) {
          // recupere les comptes
          const fetchedAccounts = await this.web3Instance.eth.getAccounts();

          // le premier compte est le compte courant connecter via metamask
          this.currentAddress = fetchedAccounts[0];
        }
      });
    } else {
      console.log("MetaMask is not installed");
    }
  }

  beforeDestroy() {
    if (this.web3Instance) {
      this.web3Instance = null;
    }
  }

  // Deploie le contrat sur la blockchain
  async deploy() {
    // recuperation du code du contrat
    // pour le deploy de contact il faut le bytescode que truffle génere quand on compule le contact
    const contractByteCode = ElectionContract.bytecode;

    // parametrages du contrat
    const candidates = this.candidates;
    const voters = this.voters;

    const startDate = Math.trunc(this.form.startDate.getTime() / 1000);
    const endDate = Math.trunc(this.form.endDate.getTime() / 1000);

    // deploiement du contrat sur la blockchain
    console.log(contractByteCode);
    this.deployedElectionContract = await this.electionContract
      .deploy({
        data: contractByteCode,
        arguments: [candidates, voters, startDate, endDate],
      })
      .send({
        from: this.currentAddress,
        //gas: 2120541,
        //gasPrice: "2000000",
      });

    // Open modal to display contract address
    this.openModal();
  }

  // Add a candidate to the election
  addCandidate() {
    if (this.candidateAddr.trim()) {
      this.candidates.push(this.candidateAddr.trim());

      this.candidateAddr = "";
    }
  }

  // Add a voter to the election
  addVoter() {
    if (this.voterAddr.trim()) {
      this.voters.push(this.voterAddr.trim());

      this.voterAddr = "";
    }
  }

  openModal() {
    const contractAddress = this.deployedElectionContract.options.address;
    const message: string =
      "L'adresse du Smart Contract est [" +
      contractAddress +
      "]. Conservez-là soigneusement, elle vous permettra ainsi à vous et aux votants d'accéder à l'élection que vous venez de créer.";
    return this.$bvModal.msgBoxOk(message, {
      title: "Smart Contract déployé",
      size: "lg",
      buttonSize: "lg",
      okVariant: "success",
      headerClass: "p-2 border-bottom-0",
      footerClass: "p-2 border-top-0",
      centered: true,
      showModal: true,
    });
  }
}
</script>
