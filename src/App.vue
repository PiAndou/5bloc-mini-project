<template>
  <div>
    <!-- This div is required so the template has only one root element (VueJS v2 limitation) -->
    <header>
      <!-- Page Title -->
      <b-navbar toggleable="lg" type="dark" variant="info">
        <b-navbar-brand>Élection du prochain président de Francieland</b-navbar-brand>
      </b-navbar>
    </header>

    <!-- <div id="nav">
      <router-link to="/">Home</router-link> |
      <router-link to="/about">About</router-link>
    </div>-->

    <div class="flex-space">
      <router-view />
    </div>
    <footer>
      <!-- Credits -->
      <b-navbar variant="faded" type="light">
        <span>
          Projet de 5BLOC, réalisé par
          <i>Oussama Akkazi, Pierre André Sarr et Yoann Desvignes</i> - Janvier 2022
        </span>
      </b-navbar>
    </footer>
  </div>
</template>