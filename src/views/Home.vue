<template>
  <b-container fluid class="fillspace box red">
    <b-row v-if="deployedElectionContract">
      <b-col>
        <!-- Informative Section -->
        <b-row class="orange">
          <!-- <h2>Description de l'élection</h2> -->
          <!-- <p>Ici décrire le contexte de l'élection (+ les dates), et expliquer les actions possibles genre voter déléguer etc.</p> -->
          <b-card header="Description de l'élection">
            <b-card-text>Ici décrire le contexte de l'élection (+ les dates), et expliquer les actions possibles genre voter déléguer etc.</b-card-text>
          </b-card>
        </b-row>

        <!-- Voter Section -->
        <b-row class="box green">
          <b-card header="Votre profil de votant">
            <!-- Voter address -->
            <b-card-text>
              <span v-if="currentAddress">Votre adresse actuelle : {{ currentAddress }}</span>
              <span v-else>Veuillez vous connecter sur MetaMask</span>
            </b-card-text>

            <!-- Informative text on voting -->
            <b-card-text>Afin de pouvoir voter, vous devez avoir été ajouté à la liste des votants par le responsable de l'élection. Contactez ce dernier pour toute demande à ce sujet.</b-card-text>

            <!-- Vote Section -->
            <b-card-text v-if="currentVoter">
              <!-- If can vote -->
              <div v-if="currentVoter.voteWeight">
                <span class="box green">Vous êtes autorisé à voter</span>

                <!-- Vote form -->
                <b-form
                  @submit.prevent="vote"
                  v-if="!currentVoter.hasVoted && !currentVoter.hasDelegated"
                >
                  <label class="sr-only" for="Candidate Address">Adresse du candidat :</label>
                  <b-input-group prepend="@" class="mb-2 mr-sm-2 mb-sm-0">
                    <b-form-input
                      v-model="candidateVoteAddr"
                      placeholder="Entrer une adresse"
                      required
                    ></b-form-input>
                  </b-input-group>
                  <b-button type="submit" variant="primary">Voter</b-button>
                </b-form>

                <span
                  v-else-if="!currentVoter.hasDelegated"
                  class="box red"
                >Vous avez déjà voté pour : {{ currentVoter.votedFor }}</span>
              </div>
              <span
                v-else-if="!currentVoter.hasDelegated"
                class="box red"
              >Vous n'êtes pas autorisé à voter</span>
            </b-card-text>

            <hr />

            <!-- Informative text on delegating -->
            <b-card-text>[Ici explication de la délégation]</b-card-text>

            <!-- Delegation Section -->
            <b-card-text v-if="currentVoter && !currentVoter.hasVoted">
              <!-- Delegation form -->
              <b-form @submit.prevent="delegateVote" v-if="!currentVoter.hasDelegated">
                <label class="sr-only" for="Receiver Address">Adresse du délégué :</label>
                <b-input-group prepend="@" class="mb-2 mr-sm-2 mb-sm-0">
                  <b-form-input
                    v-model="delegateVoteAddr"
                    placeholder="Entrer une adresse"
                    required
                  ></b-form-input>
                </b-input-group>
                <b-button type="submit" variant="primary">Déléguer</b-button>
              </b-form>
              <span v-else class="box red">
                Vous avez délégué votre vote à :
                {{ currentVoter.delegatedTo }}
              </span>
            </b-card-text>
          </b-card>
        </b-row>
      </b-col>

      <!-- Candidates Section -->
      <b-col class="box blue" v-if="currentVoter">
        <b-card header="Section des candidats">
          <b-list-group v-if="!currentVoter.hasVoted">
            <b-list-group-item v-for="candidate in candidates" :key="candidate">{{ candidate }}</b-list-group-item>
          </b-list-group>
        </b-card>
      </b-col>
    </b-row>
    <b-form @submit.prevent="getDeployedContract" v-else>
      <b-form-group
        id="input-group-1"
        label="Conctract address:"
        label-for="input-1"
        description="The address of the contract"
      >
        <b-form-input
          id="input-1"
          v-model="deployedElectionContractAddr"
          placeholder="Enter address"
          required
        ></b-form-input>
      </b-form-group>

      <b-button type="submit" variant="primary">Submit</b-button>
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
            <button @click="currentAddress = account.address">Make default</button>
            <button @click="unlockAccount(account.address, account.password)">Unlock</button>
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

  stubAccounts: any = [
    {
      "address": "0x02d5D910515F7264E92B50980AeBeeb026ad9aa6",
      "password": "80k83"
    },
    {
      "address": "0x74989d4Ba8E319Df30c04065cF3d05074E2186FE",
      "password": "g1pp5"
    },
    {
      "address": "0x411EE7fcA28c9fdEE82e8a060c9440c1526498bA",
      "password": "a0z56"
    },
    {
      "address": "0xDD95E03D7620e205e9911c762dDCa813AA424e2e",
      "password": "0v1sn"
    },
    {
      "address": "0x74ceE509ddeC4DD8827E50603D582bDb5571bF3A",
      "password": "adzkx"
    },
    {
      "address": "0x1d7D31fD97BbcC0f86e6f7bb4a285cd724328a11",
      "password": "8m674"
    }
  ];

  async mounted() {
    const web3Provider = new Web3.providers.WebsocketProvider(
      "ws://localhost:7545"
    );

    if (typeof (window as any).ethereum !== 'undefined') {
      console.log('MetaMask is installed!');

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

    if (this.electionContract) {
      this.electionContract = null;
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
    const candidatesCount = Number(await this.deployedElectionContract.methods
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
