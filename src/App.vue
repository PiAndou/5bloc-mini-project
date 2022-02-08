<template>
  <div class="flex-space">
    <!-- This div is required so the template has only one root element (VueJS v2 limitation) -->
    <header>
      <b-navbar variant="dark" type="dark" class="header-navbar">
        <!-- Page title -->
        <b-navbar-brand>Élection du prochain président</b-navbar-brand>

        <!-- Pages navigation -->
        <b-navbar-nav>
          <b-nav-item :disabled="$route.name === 'Home'"
            ><router-link :to="{ name: 'Home' }"
              >Accueil
            </router-link></b-nav-item
          >
          <b-nav-item :disabled="$route.name === 'Deploy'"
            ><router-link :to="{ name: 'Deploy' }"
              >Déployer
            </router-link></b-nav-item
          >
        </b-navbar-nav>
      </b-navbar>
    </header>

    <!-- Views routing -->
    <div class="fill-space">
      <router-view />
    </div>

    <footer>
      <!-- Credits -->
      <b-navbar variant="faded" type="light" class="footer-navbar">
        <span>
          <b>SUPINFO</b> Projet de 5BLOC, réalisé par
          <i>Oussama Akkazi, Pierre André Sarr et Yoann Desvignes</i> - Janvier
          2022
        </span>
      </b-navbar>
    </footer>
  </div>
</template>