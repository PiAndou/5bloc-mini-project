<template>
  <div style="height: 100%; display: flex; flex-direction: column;">
    <b-navbar toggleable="lg" type="dark" variant="info">
      <b-navbar-brand href="#">Élection du prochain président de Francieland</b-navbar-brand>

      <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

      <b-collapse id="nav-collapse" is-nav>
        <b-navbar-nav>
          <b-nav-item href="/" :disabled="$route.name === 'Home'">Home</b-nav-item>
          <b-nav-item href="/deploy" :disabled="$route.name === 'Deploy'">Deploy</b-nav-item>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>

    <b-container fluid style="flex: 1 0 auto;">
      <router-view />
    </b-container>

    <footer style="flex-shrink: 0;">
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

<script>

</script>

<style>
</style>
