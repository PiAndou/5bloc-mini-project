<template>
  <b-container fluid>
    <b-row v-if="deployedElectionContract">
      <b-col class="margin-right-30">
        <!-- Informative Section -->
        <b-row class="container-card">
          <!-- <h2>Description de l'élection</h2> -->
          <b-card header="Description de l'élection">
            <b-card-text>
              <p>
                Adresse du Smart Contract associée :
                <b>{{ deployedElectionContractAddr }}</b>
              </p>
              Cette élection se déroule du <b>{startDate} au {endDate}</b>. Vous
              ne pourrez voter qu'entre ces dates.<br />
              Une fois l'élection terminée, l'identité du gagnant s'affichera
              ici.
            </b-card-text>
          </b-card>
        </b-row>

        <!-- Voter Section -->
        <b-row class="container-card">
          <b-card header="Votre profil de votant">
            <!-- Voter address -->
            <b-card-text>
              <span v-if="currentAddress"
                >Votre adresse actuelle est : <b>{{ currentAddress }}</b></span
              >
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
              <div v-if="currentVoter.voteWeight">
                <b-alert variant="success" show
                  >Vous êtes autorisé à voter</b-alert
                >

                <!-- Vote form -->
                <b-form
                  @submit.prevent="vote"
                  v-if="!currentVoter.hasVoted && !currentVoter.hasDelegated"
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
                  v-else-if="!currentVoter.hasDelegated"
                >
                  Vous avez déjà voté pour : {{ currentVoter.votedFor }}
                </b-alert>
              </div>
              <b-alert
                variant="danger"
                show
                v-else-if="!currentVoter.hasDelegated"
              >
                Vous n'êtes pas autorisé à voter
              </b-alert>
            </b-card-text>

            <hr />

            <!-- Informative text on delegating -->
            <b-card-text
              >Il vous est possible de déléguer votre vote à un autre
              votant.</b-card-text
            >

            <!-- Delegation Section -->
            <b-card-text v-if="currentVoter && !currentVoter.hasVoted">
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
              <b-alert variant="danger" show v-else>
                Vous avez délégué votre vote à : {{ currentVoter.delegatedTo }}
              </b-alert>
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
        </b-card>
      </b-col>
    </b-row>

    <!-- Choosing contract Section -->
    <b-form @submit.prevent="getDeployedContract" v-else>
      <p>
        Afin de pouvoir consulter et interagir avec une élection en particulier,
        veuillez renseigner ci-dessous l'adresse du Smart Contract relié à
        l'élection souhaitée.<br />
        Si vous souhaitez créer votre propre élection en déployant un nouveau
        Smart Contract, cliquez sur le bouton <b>Déployer</b> en haut à droite
        de l'écran.
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

    <!-- left for debug to be removed in future -->
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
export default class Home extends Vue {
  web3Instance: Web3 | null = null;
  deployedElectionContractAddr: string | null = null;
  deployedElectionContract: any = null;
  currentAddress: string | null = null;
  currentVoter: any = null;
  candidates: any[] = [];

  candidateVoteAddr: string | null = null;
  delegateVoteAddr: string | null = null;

  stubAccounts: any = [];

  async mounted() {
    const web3Provider = new Web3.providers.HttpProvider(
      //"http://172.25.0.102:8545"
      "http://192.168.12.146:8545"
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
    } else {
      console.log("MetaMask is not installed");
    }
  }

  beforeDestroy() {
    if (this.web3Instance) {
      this.web3Instance = null;
    }
  }

  async unlockAccount(address: string, password: string) {
    // unlock for a long time
    this.web3Instance!.eth.personal.unlockAccount(address, password, 15000);

    this.currentVoter = await this.getCurrentVoter();
  }

  async getDeployedContract() {
    this.deployedElectionContract = new this.web3Instance!.eth.Contract(
      ElectionContract.abi as any,
      this.deployedElectionContractAddr!
    ) as any;

    this.currentVoter = await this.getCurrentVoter();
    this.candidates = await this.getAllCandidates();
  }

  async getCurrentVoter() {
    const res = await this.deployedElectionContract.methods
      .getCurrentVoter()
      .call({ from: this.currentAddress });

    console.log("currentVoter", res);

    return res;
  }

  async addVoters() {
    const res = await this.deployedElectionContract.methods
      .addVoters(["0xa8fF839D83Bd7D853d8B75506589eBeABB6Cb1DF"])
      .call({ from: this.currentAddress });
  }

  async vote() {
    const res = await this.deployedElectionContract.methods
      .vote(this.candidateVoteAddr)
      .send({ from: this.currentAddress });

    this.candidateVoteAddr = null;

    // Update current voter
    this.currentVoter = await this.getCurrentVoter();

    console.log("voted", res);
  }

  async delegateVote() {
    const res = await this.deployedElectionContract.methods
      .delegateVote(this.delegateVoteAddr)
      .send({ from: this.currentAddress });

    this.delegateVoteAddr = null;

    // Update current voter
    this.currentVoter = await this.getCurrentVoter();

    console.log("voted", res);
  }

  async getAllCandidates() {
    const candidates = [];
    const candidatesCount = Number(
      await this.deployedElectionContract.methods
        .candidatesCount()
        .call({ from: this.currentAddress })
    );

    console.log("candidatesCount", typeof candidatesCount, candidatesCount);

    for (const [i] of new Array(candidatesCount).entries()) {
      console.log("candidate index", typeof i, i);

      const candidate = await this.deployedElectionContract.methods
        .candidatesList(i)
        .call({ from: this.currentAddress });

      candidates.push(candidate);
    }

    console.log("candiates", candidates);

    return candidates;
  }

  async getWinner() {
    const res = await this.deployedElectionContract.methods
      .getWinner()
      .call({ from: this.currentAddress });

    console.log("winner", res);
  }
}
</script>
