<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const BOARD_SIZE = 20;
const INITIAL_SPEED = 200; 

const snake = ref([]);
const food = ref({});
const direction = ref({ x: 0, y: -1 });
const pendingDirection = ref({ x: 0, y: -1 });
const score = ref(0);
const isGameOver = ref(false);
const gameActive = ref(false);
const gameInterval = ref(null);

const leaderboard = ref([]);
const isLoading = ref(true);

function initializeGame() {
  snake.value = [{ x: 10, y: 10 }];
  direction.value = { x: 0, y: -1 };
  pendingDirection.value = { x: 0, y: -1 };
  score.value = 0;
  isGameOver.value = false;
  gameActive.value = false;
  generateFood();
  if (gameInterval.value) clearInterval(gameInterval.value);
}

function startGame() {
  initializeGame();
  gameActive.value = true;
  gameInterval.value = setInterval(gameLoop, INITIAL_SPEED);
}

function gameLoop() {
  if (!gameActive.value) return;

  direction.value = pendingDirection.value;
  const newHead = {
    x: snake.value[0].x + direction.value.x,
    y: snake.value[0].y + direction.value.y
  };

  if (
    newHead.x < 0 || newHead.x >= BOARD_SIZE ||
    newHead.y < 0 || newHead.y >= BOARD_SIZE ||
    isPositionOnSnake(newHead, true)
  ) {
    endGame();
    return;
  }

  snake.value.unshift(newHead);

  if (newHead.x === food.value.x && newHead.y === food.value.y) {
    score.value += 10;
    generateFood();
  } else {
    snake.value.pop();
  }
}

function generateFood() {
  let newFoodPosition;
  do {
    newFoodPosition = {
      x: Math.floor(Math.random() * BOARD_SIZE),
      y: Math.floor(Math.random() * BOARD_SIZE)
    };
  } while (isPositionOnSnake(newFoodPosition));
  food.value = newFoodPosition;
}

function isPositionOnSnake(position, ignoreHead = false) {
  const body = ignoreHead ? snake.value.slice(1) : snake.value;
  return body.some(segment => segment.x === position.x && segment.y === position.y);
}

function endGame() {
  gameActive.value = false;
  isGameOver.value = true;
  clearInterval(gameInterval.value);
  saveScore();
}

async function saveScore() {
  if (score.value === 0) return;
  try {
    const playerName = prompt("Game Over! Masukkan nama Anda:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: 'Snake',
      score: score.value
    });
    fetchLeaderboard();
  } catch (error) {
    console.error("Gagal menyimpan skor:", error);
  }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/Snake');
    leaderboard.value = response.data;
  } catch (error)
 {
    console.error("Gagal mengambil leaderboard Snake:", error);
  } finally {
    isLoading.value = false;
  }
}

function handleKeyDown(event) {
  event.preventDefault();
  const key = event.key;
  let newDirection = { ...pendingDirection.value };

  if ((key === 'ArrowUp' || key.toLowerCase() === 'w') && direction.value.y === 0) newDirection = { x: 0, y: -1 };
  else if ((key === 'ArrowDown' || key.toLowerCase() === 's') && direction.value.y === 0) newDirection = { x: 0, y: 1 };
  else if ((key === 'ArrowLeft' || key.toLowerCase() === 'a') && direction.value.x === 0) newDirection = { x: -1, y: 0 };
  else if ((key === 'ArrowRight' || key.toLowerCase() === 'd') && direction.value.x === 0) newDirection = { x: 1, y: 0 };
  
  pendingDirection.value = newDirection;
}

onMounted(() => {
  initializeGame();
  fetchLeaderboard();
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
  if (gameInterval.value) clearInterval(gameInterval.value);
});

const boardStyle = computed(() => ({
  gridTemplateColumns: `repeat(${BOARD_SIZE}, 1fr)`,
  gridTemplateRows: `repeat(${BOARD_SIZE}, 1fr)`,
}));
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>

    <div class="snake-card">
      <div class="game-area">
        <h1>Snake</h1>
        <div class="board" :style="boardStyle">
          <div 
            v-for="(segment, index) in snake" 
            :key="`snake-${index}`" 
            class="snake-segment" 
            :class="{ 'head': index === 0 }"
            :style="{ gridColumn: segment.x + 1, gridRow: segment.y + 1 }"
          ></div>
          <div 
            class="food" 
            :style="{ gridColumn: food.x + 1, gridRow: food.y + 1 }"
          ></div>
          <div v-if="!gameActive" class="overlay">
            <h2 v-if="isGameOver">Game Over!</h2>
            <button @click="startGame" class="action-button">
              {{ isGameOver ? 'Main Lagi' : 'Mulai Bermain' }}
            </button>
          </div>
        </div>
      </div>
      <div class="info-area">
        <div class="info-box mobile-controls">
           <h3>KONTROL</h3>
           <div class="d-pad">
              <div class="d-pad-cell"></div>
              <button @click="pendingDirection = {x: 0, y: -1}" class="mobile-btn">↑</button>
              <div class="d-pad-cell"></div>
              <button @click="pendingDirection = {x: -1, y: 0}" class="mobile-btn">←</button>
              <div class="d-pad-cell center"></div>
              <button @click="pendingDirection = {x: 1, y: 0}" class="mobile-btn">→</button>
              <div class="d-pad-cell"></div>
              <button @click="pendingDirection = {x: 0, y: 1}" class="mobile-btn">↓</button>
              <div class="d-pad-cell"></div>
           </div>
        </div>
        <div class="info-box">
          <h3>SKOR</h3>
          <p class="score-value">{{ score }}</p>
        </div>
        <div class="info-box leaderboard-box">
          <h3>🏆 LEADERBOARD</h3>
          <div v-if="isLoading" class="loading-text">Memuat...</div>
          <ul v-else-if="leaderboard.length > 0">
            <li v-for="(item, index) in leaderboard" :key="item.id">
              <span>#{{ index + 1 }} {{ item.player_name }}</span>
              <strong>{{ item.score }}</strong>
            </li>
          </ul>
          <div v-else class="loading-text">Belum ada data.</div>
        </div>
        <div class="info-box desktop-controls">
          <h3>KONTROL</h3>
          <p class="controls-text">Gunakan tombol panah atau W, A, S, D untuk bergerak.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  min-height: 100vh;
  padding: 6rem 1.5rem 1.5rem 1.5rem;
  font-family: 'Poppins', sans-serif;
  color: var(--text-primary, #e0e0e0);
}

.back-button {
  position: absolute;
  top: 1.5rem; left: 1.5rem;
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
.back-button:hover { background-color: #2c3e50; color: #fff; }

.snake-card {
  display: flex;
  flex-direction: column;
  gap: 2rem;
  width: 100%;
  max-width: 1000px;
}

.game-area { text-align: center; }
h1 {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--accent-color, #e94560);
  margin-bottom: 1rem;
}

.board {
  display: grid;
  aspect-ratio: 1 / 1;
  width: 100%;
  max-width: 60vh;
  margin: 0 auto;
  position: relative;
  background-color: #0c0c14;
  border: 4px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 8px;
  --grid-size: calc(100% / 20);
  background-image:
    linear-gradient(to right, rgba(255,255,255,0.05) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(255,255,255,0.05) 1px, transparent 1px);
  background-size: var(--grid-size) var(--grid-size);
}

.snake-segment {
  background-color: #33ff33;
  border-radius: 20%;
  box-shadow: 0 0 8px #33ff33;
}
.snake-segment.head {
  background-color: #9dff9d;
  box-shadow: 0 0 12px #9dff9d;
}

.food {
  background-color: #ff3333;
  border-radius: 50%;
  box-shadow: 0 0 10px #ff3333;
  animation: pulse 1s infinite ease-in-out;
}
@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

.overlay {
  position: absolute; top: 0; left: 0;
  width: 100%; height: 100%;
  background-color: rgba(0, 0, 0, 0.75);
  display: flex; flex-direction: column;
  justify-content: center; align-items: center;
  border-radius: 4px;
}
.overlay h2 { font-size: 2rem; margin-bottom: 1.5rem; color: #fff; }
.action-button {
  padding: 12px 24px; font-size: 1.2rem; font-weight: 600; color: #fff;
  background-color: var(--accent-color, #e94560);
  border: none; border-radius: 8px; cursor: pointer;
  transition: background-color 0.2s ease;
}
.action-button:hover { background-color: var(--accent-hover, #ff6e87); }

.info-area {
  display: flex; flex-direction: column; gap: 1.5rem;
  width: 100%; max-width: 400px; margin: 0 auto;
}
.info-box {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 12px; padding: 1rem;
}
.info-box h3 {
  font-size: 1.1rem; font-weight: 600; margin: 0 0 1rem 0;
  padding-bottom: 0.5rem; text-align: center;
  border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  color: var(--accent-color, #e94560);
}
.score-value { font-size: 2.5rem; font-weight: 700; text-align: center; }

.d-pad {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.5rem;
  max-width: 250px; 
  margin: 0 auto; 
}
.mobile-btn {
  aspect-ratio: 1 / 1; 
  font-size: 1.8rem; 
  font-weight: bold;
  background-color: rgba(255,255,255,0.1);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  color: var(--text-primary, #e0e0e0);
  border-radius: 8px; cursor: pointer;
}

.mobile-btn:active { background-color: rgba(255,255,255,0.2); }
.d-pad-cell { background: transparent; }

.leaderboard-box ul { list-style: none; padding: 0; margin: 0; max-height: 200px; overflow-y: auto; }
.leaderboard-box li { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.leaderboard-box li:last-child { border-bottom: none; }
.leaderboard-box li span { color: var(--text-secondary); }
.leaderboard-box li strong { color: var(--text-primary); }
.loading-text { text-align: center; color: var(--text-secondary); }

.desktop-controls { text-align: center; }
.controls-text { color: var(--text-secondary); }

@media (min-width: 992px) {
  .page-container {
    align-items: center;
    padding: 1.5rem;
  }
  .snake-card {
    flex-direction: row;
    align-items: flex-start;
  }
  .game-area { flex: 2; }
  .info-area {
    flex: 1;
    max-width: 350px;
  }

  .mobile-controls {
    display: none;
  }
}
</style>