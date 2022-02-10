<template>
  <b-container fluid>
    <b-row
      v-if="deployedElectionContract && contractStartDate && contractEndDate"
    >
      <b-col class="margin-right-30">
        <!-- Informative Section -->
        <b-row class="container-card">
          <b-card header="Description de l'élection">
            <b-card-text>
              <p>
                Adresse du Smart Contract associé :
                <b>{{ deployedElectionContractAddr }}</b>
              </p>
              Cette élection se déroule du
              <b
                >{{ contractStartDate.toLocaleDateString() }} au
                {{ contractEndDate.toLocaleDateString() }}</b
              >. Vous ne pourrez voter qu'entre ces dates. <br />Une fois
              l'élection terminée, l'identité du gagnant s'affichera ici,
              ci-dessous. <br /><span v-if="winnerAddress != null" class="green"
                >Le gagnant est : <b>{{ winnerAddress }}</b></span
              >
            </b-card-text>
          </b-card>
        </b-row>

        <!-- Voter Section -->
        <b-row class="container-card">
          <b-card header="Votre profil de votant">
            <!-- Voter address -->
            <b-card-text>
              <span v-if="currentAddress">
                Votre adresse actuelle est :
                <b>{{ currentAddress }}</b>
              </span>
              <span v-else class="red"
                >Veuillez vous connecter sur MetaMask</span
              >
            </b-card-text>

            <!-- Informative text on voting -->
            <b-card-text
              >Afin de pouvoir voter, vous devez avoir été ajouté à la liste des
              votants par le responsable de l'élection. Contactez ce dernier
              pour toute demande à ce sujet.</b-card-text
            >

            <!-- Vote Section -->
            <b-card-text v-if="currentVoter">
              <!-- If can vote -->
              <div v-if="currentVoter.voteWeight != 0">
                <b-alert variant="success" show
                  >Vous êtes autorisé à voter</b-alert
                >

                <!-- Vote form -->
                <b-form
                  @submit.prevent="vote"
                  v-if="
                    isElectionOpen &&
                    !currentVoter.hasVoted &&
                    !currentVoter.hasDelegated
                  "
                >
                  <div class="form-content">
                    <b-input-group prepend="@" class="form-group">
                      <b-form-input
                        v-model="candidateVoteAddr"
                        placeholder="Entrer une adresse"
                        required
                      ></b-form-input>
                    </b-input-group>
                    <b-button type="submit" variant="primary">Voter</b-button>
                  </div>
                </b-form>

                <!-- Informations about voting restrictions -->
                <b-alert
                  variant="danger"
                  show
                  v-else-if="isElectionOpen && !currentVoter.hasDelegated"
                  >Vous avez déjà voté pour :
                  {{ currentVoter.votedFor }}</b-alert
                >
              </div>
              <b-alert
                variant="danger"
                show
                v-else-if="isElectionOpen && !currentVoter.hasDelegated"
                >Vous n'êtes pas autorisé à voter</b-alert
              >
            </b-card-text>

            <hr />

            <!-- Informative text on delegating -->
            <b-card-text
              v-if="
                currentVoter &&
                currentVoter.voteWeight != 0 &&
                !currentVoter.hasVoted
              "
              >Il vous est possible de déléguer votre vote à un autre
              votant.</b-card-text
            >

            <!-- Delegation Section -->
            <b-card-text
              v-if="
                currentVoter &&
                currentVoter.voteWeight != 0 &&
                !currentVoter.hasVoted
              "
            >
              <!-- Delegation form -->
              <b-form
                @submit.prevent="delegateVote"
                v-if="!currentVoter.hasDelegated"
              >
                <div class="form-content">
                  <b-input-group prepend="@" class="form-group">
                    <b-form-input
                      v-model="delegateVoteAddr"
                      placeholder="Entrer une adresse"
                      required
                    ></b-form-input>
                  </b-input-group>
                  <b-button type="submit" variant="primary">Déléguer</b-button>
                </div>
              </b-form>
              <b-alert variant="danger" show v-else
                >Vous avez délégué votre vote à :
                {{ currentVoter.delegatedTo }}</b-alert
              >
            </b-card-text>
          </b-card>
        </b-row>
      </b-col>

      <!-- Candidates Section -->
      <b-col class="container-card" v-if="currentVoter">
        <b-card header="Section des candidats">
          <b-list-group v-if="!currentVoter.hasVoted">
            <b-list-group-item
              v-for="candidate in candidates"
              :key="candidate"
              >{{ candidate }}</b-list-group-item
            >
          </b-list-group>
          <BarChart
            v-else-if="chartData"
            :chartData="chartData"
            :options="chartOptions"
            :key="chartUpdateKey"
          ></BarChart>
        </b-card>
      </b-col>
    </b-row>

    <!-- Choosing contract Section -->
    <b-form @submit.prevent="getDeployedContract" v-else>
      <p>
        Afin de pouvoir consulter et interagir avec une élection en particulier,
        veuillez renseigner ci-dessous l'adresse du Smart Contract relié à
        l'élection concernée.
        <br />Si vous souhaitez créer votre propre élection en déployant un
        nouveau Smart Contract, cliquez sur le bouton <b>Déployer</b> en haut à
        droite de l'écran.
      </p>

      <div class="form-content">
        <b-form-group
          id="input-group-1"
          label="Adresse du contract :"
          label-for="input-1"
          class="form-group"
        >
          <b-form-input
            id="input-1"
            v-model="deployedElectionContractAddr"
            placeholder="Entrer une adresse"
            required
          ></b-form-input>
        </b-form-group>
        <b-button type="submit" variant="primary">Accéder</b-button>
      </div>
    </b-form>
  </b-container>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import ElectionContract from "@/../build/contracts/ElectionContract.json";
import Web3 from "web3";
import { Bar } from "vue-chartjs";
import BarChart from "@/components/BarChart.vue";

@Component({
  extends: Bar,
  components: {
    BarChart,
  },
})
export default class Home extends Vue {
  web3Instance: Web3 | null = null;
  deployedElectionContractAddr: string | null = null;
  deployedElectionContract: any = null;
  contractStartDate: Date | null = null;
  contractEndDate: Date | null = null;
  currentDate: Date | number | null = null;
  isElectionOpen = false;
  winnerAddress: string | null = null;
  currentAddress: string | null = null;
  currentVoter: any = null;
  candidates: any[] = [];

  candidateVoteAddr: string | null = null;
  delegateVoteAddr: string | null = null;

  chartData: any = null;
  chartOptions = {
    responsive: true,
    scales: {
      offset: false,
    },
  };
  chartUpdateKey = 0;

  async mounted() {
    if (typeof (window as any).ethereum !== "undefined") {
      (window as any).ethereum.request({ method: "eth_requestAccounts" });

      this.web3Instance = new Web3((window as any).ethereum);

      // recupere les comptes
      const fetchedAccounts = await this.web3Instance.eth.getAccounts();

      // le premier compte est le compte courant connecter via metamask
      this.currentAddress = fetchedAccounts[0];

      // actualise le compte courant de metamask quand il change de compte
      (window as any).ethereum.on("accountsChanged", async () => {
        if (this.web3Instance) {
          // recupere les comptes
          const fetchedAccounts = await this.web3Instance.eth.getAccounts();

          // le premier compte est le compte courant connecter via metamask
          this.currentAddress = fetchedAccounts[0];

          // Update current voter
          if (this.deployedElectionContract) {
            this.currentVoter = await this.getCurrentVoter();
          }
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

  // recupere le contrat deployé
  async getDeployedContract() {
    this.deployedElectionContract = new this.web3Instance!.eth.Contract(
      ElectionContract.abi as any,
      this.deployedElectionContractAddr!
    ) as any;

    // Get dates from contract
    const startDate = await this.deployedElectionContract.methods
      .startDate()
      .call();
    const endDate = await this.deployedElectionContract.methods
      .endDate()
      .call();
    // Transform dates to display them
    this.contractStartDate = new Date(Number(startDate) * 1000);
    this.contractEndDate = new Date(Number(endDate) * 1000);
    // Get current date
    this.currentDate = new Date();
    this.currentDate = Math.trunc(this.currentDate.getTime() / 1000);

    // Check if election is open
    if (this.currentDate >= startDate && this.currentDate <= endDate) {
      this.isElectionOpen = true;
    } else {
      this.isElectionOpen = false;
    }

    // Get winner if election is over
    if (this.currentDate >= endDate) {
      this.getWinner();
    } else {
      this.winnerAddress = null;
    }

    await this.updateAll();
  }

  // Update all smart contract data
  async updateAll() {
    this.currentVoter = await this.getCurrentVoter();
    this.candidates = await this.getAllCandidates();

    const votes = [];

    // recupere le nombre de vote de chaque candidat
    for (const candidateAddr of this.candidates) {
      const vote = await this.getCandidateVotes(candidateAddr);

      votes.push(Number(vote));
    }

    this.chartData = {
      labels: this.candidates.map((addr) => addr.substr(0, 10)),
      datasets: [
        {
          label: "# of Votes",
          data: votes,
          backgroundColor: [
            "rgba(255, 99, 132, 0.2)",
            "rgba(54, 162, 235, 0.2)",
            "rgba(255, 206, 86, 0.2)",
            "rgba(75, 192, 192, 0.2)",
            "rgba(153, 102, 255, 0.2)",
            "rgba(255, 159, 64, 0.2)",
          ],
          borderColor: [
            "rgba(255, 99, 132, 1)",
            "rgba(54, 162, 235, 1)",
            "rgba(255, 206, 86, 1)",
            "rgba(75, 192, 192, 1)",
            "rgba(153, 102, 255, 1)",
            "rgba(255, 159, 64, 1)",
          ],
          borderWidth: 1,
        },
      ],
    };

    this.$nextTick(() => {
      this.chartUpdateKey++;
    });
  }

  // recupere / met a jour le voter connecté actuellement
  async getCurrentVoter() {
    const res = await this.deployedElectionContract.methods
      .getSpecificVoter()
      .call({ from: this.currentAddress });

    return res;
  }

  // vote pour un candidat
  async vote() {
    const res = await this.deployedElectionContract.methods
      .vote(this.candidateVoteAddr)
      .send({ from: this.currentAddress });

    this.candidateVoteAddr = null;

    // Update smart contract data
    await this.updateAll();
  }

  // delegue le vote a un autre voter
  async delegateVote() {
    const res = await this.deployedElectionContract.methods
      .delegateVote(this.delegateVoteAddr)
      .send({ from: this.currentAddress });

    this.delegateVoteAddr = null;

    // Update smart contract data
    await this.updateAll();
  }

  // recupere tout les candiats a l'election
  async getAllCandidates() {
    const candidates = [];
    const candidatesCount = Number(
      await this.deployedElectionContract.methods
        .candidatesCount()
        .call({ from: this.currentAddress })
    );

    // obliger de recuperer les candidats un par un cars le mapping ne renvoie pas tout les utilisateurs cars il est dynamique
    for (const [i] of new Array(candidatesCount).entries()) {
      const candidate = await this.deployedElectionContract.methods
        .candidatesList(i)
        .call({ from: this.currentAddress });

      candidates.push(candidate);
    }

    return candidates;
  }

  // recupere le nombre de vote d'un candidat
  async getCandidateVotes(addr: string) {
    const res = await this.deployedElectionContract.methods
      .candidates(addr)
      .call({ from: this.currentAddress });

    return res;
  }

  // recupere le gagnant d'une election
  async getWinner() {
    const res = await this.deployedElectionContract.methods
      .getWinner()
      .call({ from: this.currentAddress });

    this.winnerAddress = res;
  }
}
</script>
