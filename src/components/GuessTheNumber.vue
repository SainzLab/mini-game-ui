<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';

const randomNumber = ref(Math.floor(Math.random() * 100) + 1);
const guess = ref('');
const message = ref('Tebak angka antara 1 dan 100');
const attempts = ref(0);
const gameOver = ref(false);
const feedbackClass = ref('');

const leaderboard = ref([]);
const isLoading = ref(true);

const successMessage = computed(() => {
  return `🎉 Selamat! Anda menebak dengan benar dalam <strong>${attempts.value}</strong> percobaan.`;
});

function triggerFeedbackAnimation() {
  feedbackClass.value = 'shake';
  setTimeout(() => {
    feedbackClass.value = '';
  }, 500); 
}

function checkGuess() {
  if (gameOver.value || !guess.value) return;

  const userGuess = parseInt(guess.value);

  if (isNaN(userGuess) || userGuess < 1 || userGuess > 100) {
    message.value = 'Masukkan angka antara 1 dan 100.';
    triggerFeedbackAnimation();
    guess.value = '';
    return;
  }
  
  attempts.value++;

  if (userGuess === randomNumber.value) {
    message.value = successMessage.value;
    gameOver.value = true;
    saveScore();
  } else if (userGuess > randomNumber.value) {
    message.value = 'Terlalu tinggi! Coba lagi.';
    triggerFeedbackAnimation();
  } else {
    message.value = 'Terlalu rendah! Coba lagi.';
    triggerFeedbackAnimation();
  }
  guess.value = '';
}

function resetGame() {
  randomNumber.value = Math.floor(Math.random() * 100) + 1;
  guess.value = '';
  message.value = 'Tebak angka antara 1 dan 100';
  attempts.value = 0;
  gameOver.value = false;
  feedbackClass.value = '';
}

async function saveScore() {
  try {
    const playerName = prompt("Selamat! Masukkan nama Anda untuk leaderboard:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;

    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName.trim(),
      game_name: 'Tebak Angka',
      score: attempts.value
    });
    fetchLeaderboard();
  } catch (error) {
    console.error("Gagal menyimpan skor:", error);
    alert("Gagal menyimpan skor. Pastikan API server berjalan.");
  }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores');
    leaderboard.value = response.data
      .filter(s => s.game_name === 'Tebak Angka')
      .sort((a, b) => a.score - b.score)
      .slice(0, 5);
  } catch (error) {
    console.error("Gagal mengambil leaderboard:", error);
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchLeaderboard();
});
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>
    
    <div class="main-content">
      <div class="card game-card">
        <h1>Tebak Angka</h1>
        
        <template v-if="!gameOver">
          <p class="message" :class="feedbackClass" v-html="message"></p>
          <form @submit.prevent="checkGuess">
            <input 
              type="number" 
              v-model="guess" 
              placeholder="?" 
              class="guess-input" 
              autofocus
              min="1"
              max="100"
              :disabled="gameOver"
            >
            <button type="submit" class="action-button">Tebak</button>
          </form>
        </template>
        
        <div v-else class="game-over-container">
          <p class="message success-message" v-html="message"></p>
          <button @click="resetGame" class="action-button play-again-button">Main Lagi</button>
        </div>
      </div>

      <div class="card leaderboard-card">
        <h2>🏆 Leaderboard</h2>
        <p class="leaderboard-subtitle">Skor terendah lebih baik!</p>
        <div v-if="isLoading" class="loading-text">Memuat data...</div>
        <ul v-else-if="leaderboard.length > 0" class="leaderboard-list">
          <li v-for="(score, index) in leaderboard" :key="score.id">
            <span :class="['rank', `rank-${index + 1}`]">#{{ index + 1 }}</span>
            <span class="player">{{ score.player_name }}</span>
            <span class="score">{{ score.score }} <span class="tries">percobaan</span></span>
          </li>
        </ul>
        <div v-else class="loading-text">Belum ada skor tercatat. Jadilah yang pertama!</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  position: relative;
  display: flex;
  justify-content: center;
  min-height: 100vh;
  padding: 1.5rem;
  font-family: 'Poppins', sans-serif;
  align-items: flex-start;
  padding-top: 6rem; 
}

.back-button {
  position: absolute;
  top: 1.5rem;
  left: 1.5rem;
  padding: 0.6rem 1.2rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-secondary, #a0a0a0);
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.2s ease-in-out;
  z-index: 10;
}
.back-button:hover {
  background-color: #2c3e50;
  color: #fff;
}

.main-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
  width: 100%;
  max-width: 1000px;
}

.card {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px;
  padding: 2rem;
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  text-align: center;
  color: var(--text-primary, #e0e0e0);
}

h1 {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--accent-color, #e94560);
  margin: 0 0 1rem 0;
}

.message {
  font-size: 1.2rem;
  color: var(--text-secondary, #a0a0a0);
  margin: 1.5rem 0;
  min-height: 1.5em;
}

.success-message {
  color: #33ff33;
  font-weight: 600;
}

form {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
}

.guess-input {
  width: 120px;
  padding: 1rem;
  font-size: 3rem;
  font-weight: 700;
  text-align: center;
  background-color: var(--bg-color-deep, #10101a);
  border: 2px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 12px;
  color: #fff;
  outline: none;
  transition: all 0.2s ease;
}
.guess-input:focus {
  border-color: var(--accent-color, #e94560);
  box-shadow: 0 0 15px var(--shadow-glow, rgba(233, 69, 96, 0.5));
}
.guess-input::-webkit-outer-spin-button,
.guess-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
.guess-input[type=number] {
  -moz-appearance: textfield;
}

.action-button {
  padding: 1rem 2rem;
  font-size: 1.2rem;
  font-weight: 600;
  color: #fff;
  background-color: var(--accent-color, #e94560);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: background-color 0.2s ease;
}
.action-button:hover {
  background-color: var(--accent-hover, #ff6e87);
}

.game-over-container {
  margin-top: 1.5rem;
}
.play-again-button {
  margin-top: 1rem;
}

.shake {
  animation: shake 0.5s cubic-bezier(.36,.07,.19,.97) both;
}
@keyframes shake {
  10%, 90% { transform: translate3d(-1px, 0, 0); }
  20%, 80% { transform: translate3d(2px, 0, 0); }
  30%, 50%, 70% { transform: translate3d(-4px, 0, 0); }
  40%, 60% { transform: translate3d(4px, 0, 0); }
}

.leaderboard-card h2 {
  font-size: 1.5rem;
  margin: 0 0 0.5rem 0;
  color: var(--accent-color, #e94560);
}
.leaderboard-subtitle {
  font-size: 0.9rem;
  margin: 0 0 1.5rem 0;
  color: var(--text-secondary, #a0a0a0);
}
.leaderboard-list {
  list-style: none;
  padding: 0;
  margin: 0;
}
.leaderboard-list li {
  display: flex;
  align-items: center;
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  font-size: 1.1rem;
}
.leaderboard-list li:last-child {
  border-bottom: none;
}
.rank { font-weight: 700; min-width: 40px; }
.rank-1 { color: #ffd700; }
.rank-2 { color: #c0c0c0; }
.rank-3 { color: #cd7f32; }
.player {
  flex-grow: 1;
  text-align: left;
  padding: 0 1rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.score { font-weight: 600; color: #fff; }
.tries { font-size: 0.8rem; color: var(--text-secondary, #a0a0a0); }
.loading-text { color: var(--text-secondary, #a0a0a0); }

@media (min-width: 992px) {
  .page-container {
    align-items: center;
    padding-top: 1.5rem;
  }
  .main-content {
    flex-direction: row;
    align-items: flex-start;
  }
  .game-card {
    flex-basis: 50%;
  }
  .leaderboard-card {
    flex-basis: 50%;
  }
}
</style>