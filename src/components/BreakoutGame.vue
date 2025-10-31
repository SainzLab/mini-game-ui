<script setup>
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const VIEWBOX_WIDTH = 800;
const VIEWBOX_HEIGHT = 600;
const score = ref(0);
const lives = ref(3);
const gameState = ref('initial');
const gameArea = ref(null);
const paddle = reactive({ x: VIEWBOX_WIDTH / 2 - 60, y: VIEWBOX_HEIGHT - 40, width: 120, height: 20, speed: 10 });
const ball = reactive({ x: VIEWBOX_WIDTH / 2, y: VIEWBOX_HEIGHT / 2, radius: 10, dx: 4, dy: -4 });
const bricks = ref([]);
const keysPressed = reactive({ ArrowLeft: false, ArrowRight: false });
const leaderboard = ref([]);
const isLoading = ref(true);
const medals = ['🥇', '🥈', '🥉'];
let animationFrameId = null;
let brickMoveInterval = null;

const createBricks = () => {
  bricks.value = [];
  const brickConfig = { rows: 5, cols: 10, width: 75, height: 20, padding: 5, offsetTop: 50 };
  brickConfig.offsetLeft = (VIEWBOX_WIDTH - (brickConfig.cols * brickConfig.width + (brickConfig.cols - 1) * brickConfig.padding)) / 2;
  const colors = ["#ff1744", "#d500f9", "#6a82fb", "#00e676", "#ffea00"];
  for (let c = 0; c < brickConfig.cols; c++) {
    for (let r = 0; r < brickConfig.rows; r++) {
      bricks.value.push({
        x: c * (brickConfig.width + brickConfig.padding) + brickConfig.offsetLeft,
        y: r * (brickConfig.height + brickConfig.padding) + brickConfig.offsetTop,
        width: brickConfig.width,
        height: brickConfig.height,
        color: colors[r % colors.length],
        visible: true,
      });
    }
  }
};
const resetBallAndPaddle = () => {
  paddle.x = VIEWBOX_WIDTH / 2 - paddle.width / 2;
  ball.x = VIEWBOX_WIDTH / 2;
  ball.y = paddle.y - 50;
  ball.dx = 4 * (Math.random() > 0.5 ? 1 : -1);
  ball.dy = -4;
};
const resetGame = (isNewGame = false) => {
  if (isNewGame) {
    score.value = 0;
    lives.value = 3;
    fetchLeaderboard();
  }
  resetBallAndPaddle();
  createBricks();
  gameState.value = 'initial';
  if (animationFrameId) cancelAnimationFrame(animationFrameId);
  if (brickMoveInterval) clearInterval(brickMoveInterval);
};
const startGame = () => {
  if (gameState.value === 'playing') return;
  if (gameState.value === 'initial' || gameState.value === 'gameOver') {
    resetGame(true);
  }
  gameState.value = 'playing';
  brickMoveInterval = setInterval(moveBricksDown, 12000);
  gameLoop();
};
const gameLoop = () => {
  if (gameState.value !== 'playing') return;
  movePaddleWithKeys();
  ball.x += ball.dx;
  ball.y += ball.dy;
  handleCollisions();
  animationFrameId = requestAnimationFrame(gameLoop);
};
const moveBricksDown = () => {
  if (gameState.value !== 'playing') return;
  let shouldEndGame = false;
  bricks.value.forEach(brick => {
    if (brick.visible) {
      brick.y += brick.height + 5;
      if (brick.y + brick.height >= paddle.y) {
        shouldEndGame = true;
      }
    }
  });
  if (shouldEndGame) {
    gameState.value = 'gameOver';
    saveScore();
  }
};
const handleCollisions = () => {
  if (ball.x + ball.radius > VIEWBOX_WIDTH || ball.x - ball.radius < 0) ball.dx *= -1;
  if (ball.y - ball.radius < 0) ball.dy *= -1;
  if (ball.y + ball.radius > VIEWBOX_HEIGHT) {
    lives.value--;
    gameState.value = 'paused';
    if (lives.value <= 0) {
      gameState.value = 'gameOver';
      saveScore();
    } else {
      setTimeout(() => {
        resetBallAndPaddle();
        if (gameState.value !== 'gameOver') {
          gameState.value = 'playing';
          gameLoop();
        }
      }, 1000);
    }
    return;
  }
  if (
    ball.y + ball.radius > paddle.y && ball.y - ball.radius < paddle.y + paddle.height &&
    ball.x > paddle.x && ball.x < paddle.x + paddle.width
  ) {
    ball.dy = -Math.abs(ball.dy);
  }
  bricks.value.forEach(brick => {
    if (brick.visible) {
      if (
        ball.x + ball.radius > brick.x && ball.x - ball.radius < brick.x + brick.width &&
        ball.y + ball.radius > brick.y && ball.y - ball.radius < brick.y + brick.height
      ) {
        brick.visible = false;
        ball.dy *= -1;
        score.value += 10;
        checkAllBricksCleared();
      }
    }
  });
};
const checkAllBricksCleared = () => {
  if (bricks.value.every(b => !b.visible)) {
    score.value += 100;
    createBricks();
    gameState.value = 'paused';
    setTimeout(() => {
      resetBallAndPaddle();
      if (gameState.value !== 'gameOver') {
        gameState.value = 'playing';
        gameLoop();
      }
    }, 1000);
  }
};
async function saveScore() {
  if (score.value === 0) return;
  if (animationFrameId) cancelAnimationFrame(animationFrameId);
  if (brickMoveInterval) clearInterval(brickMoveInterval);
  try {
    const playerName = prompt("Game Over! Masukkan nama Anda:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: 'Breakout',
      score: score.value
    });
    fetchLeaderboard();
  } catch (error) { console.error("Gagal menyimpan skor:", error); }
}
async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/Breakout');
    leaderboard.value = response.data;
  } catch (error) { console.error("Gagal mengambil leaderboard:", error); }
  finally { isLoading.value = false; }
}
const updatePaddlePosition = (clientX, targetElement) => {
  if (!targetElement || gameState.value !== 'playing') return;
  const rect = targetElement.getBoundingClientRect();
  const scaleX = VIEWBOX_WIDTH / rect.width;
  let newPaddleX = (clientX - rect.left) * scaleX - paddle.width / 2;
  if (newPaddleX < 0) newPaddleX = 0;
  if (newPaddleX + paddle.width > VIEWBOX_WIDTH) newPaddleX = VIEWBOX_WIDTH - paddle.width;
  paddle.x = newPaddleX;
};
const movePaddleWithKeys = () => {
  if (keysPressed.ArrowLeft) paddle.x -= paddle.speed;
  if (keysPressed.ArrowRight) paddle.x += paddle.speed;
  if (paddle.x < 0) paddle.x = 0;
  if (paddle.x + paddle.width > VIEWBOX_WIDTH) paddle.x = VIEWBOX_WIDTH - paddle.width;
};
const handleMouseMove = (e) => updatePaddlePosition(e.clientX, gameArea.value);
const handleTouchMove = (e) => {
  e.preventDefault();
  updatePaddlePosition(e.touches[0].clientX, e.currentTarget);
};
const handleKeyDown = (e) => {
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') keysPressed[e.key] = true;
};
const handleKeyUp = (e) => {
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') keysPressed[e.key] = false;
};
onMounted(() => {
  resetGame(true);
  window.addEventListener('keydown', handleKeyDown);
  window.addEventListener('keyup', handleKeyUp);
});
onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
  window.removeEventListener('keyup', handleKeyUp);
  cancelAnimationFrame(animationFrameId);
  if (brickMoveInterval) clearInterval(brickMoveInterval);
});
const gameMessage = computed(() => {
  if (gameState.value === 'gameOver') return 'Game Over!';
  if (gameState.value === 'paused') return 'Klik untuk Lanjut';
  return 'Klik untuk Mulai';
});
const sliderThumbStyle = computed(() => {
  const thumbWidthPercent = (paddle.width / VIEWBOX_WIDTH) * 100;
  const maxLeftPercent = 100 - thumbWidthPercent;
  const paddlePositionFraction = paddle.x / (VIEWBOX_WIDTH - paddle.width);
  const leftPercent = paddlePositionFraction * maxLeftPercent;
  return { left: `${leftPercent}%`, width: `${thumbWidthPercent}%` };
});
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>
    
    <div class="breakout-card">
      <div class="game-main">
        <h1>Breakout</h1>
        <div class="stats">
          <span>Skor: <strong>{{ score }}</strong></span>
          <span class="lives">
            Nyawa: 
            <span v-for="n in lives" :key="n" class="heart">❤️</span>
          </span>
        </div>
        <div 
          class="game-area" 
          ref="gameArea"
          @click="startGame"
          @mousemove="handleMouseMove"
        >
          <svg
            :viewBox="`0 0 ${VIEWBOX_WIDTH} ${VIEWBOX_HEIGHT}`"
            class="game-board"
            preserveAspectRatio="xMidYMid meet"
          >
            <defs>
              <filter id="glow">
                <feGaussianBlur stdDeviation="3.5" result="coloredBlur"></feGaussianBlur>
                <feMerge>
                  <feMergeNode in="coloredBlur"></feMergeNode>
                  <feMergeNode in="SourceGraphic"></feMergeNode>
                </feMerge>
              </filter>
            </defs>
            <rect :width="VIEWBOX_WIDTH" :height="VIEWBOX_HEIGHT" fill="#10101a" />
            <rect :x="paddle.x" :y="paddle.y" :width="paddle.width" :height="paddle.height" fill="#e0e0e0" rx="8" class="glow-element"/>
            <circle :cx="ball.x" :cy="ball.y" :r="ball.radius" fill="#ff1744" class="glow-element"/>
            <template v-for="(brick, index) in bricks" :key="index">
              <rect v-if="brick.visible" :x="brick.x" :y="brick.y" :width="brick.width" :height="brick.height" :fill="brick.color" rx="3" stroke="#10101a" stroke-width="2"/>
            </template>
            <g v-if="gameState !== 'playing'">
              <rect x="0" y="0" :width="VIEWBOX_WIDTH" :height="VIEWBOX_HEIGHT" fill="rgba(15, 15, 25, 0.7)" />
              <text :x="VIEWBOX_WIDTH / 2" :y="VIEWBOX_HEIGHT / 2" class="game-message" text-anchor="middle">
                {{ gameMessage }}
              </text>
            </g>
          </svg>
        </div>
        <div 
          class="mobile-slider-control"
          @touchstart.prevent="handleTouchMove"
          @touchmove.prevent="handleTouchMove"
        >
          <div class="slider-track">
            <div class="slider-thumb" :style="sliderThumbStyle"></div>
          </div>
        </div>
      </div>
      
      <div class="info-area">
        <div class="info-box leaderboard-box">
          <h3>🏆 Leaderboard</h3>
          <div v-if="isLoading" class="loading-text">Memuat...</div>
          <ul v-else-if="leaderboard.length > 0" class="leaderboard-list">
            <li v-for="(item, index) in leaderboard" :key="item.id" class="leaderboard-item">
              <div class="player-info">
                <span class="rank">{{ medals[index] || `#${index + 1}` }}</span>
                <span class="player-name">{{ item.player_name }}</span>
              </div>
              <strong class="score-value">{{ item.score }}</strong>
            </li>
          </ul>
          <div v-else class="loading-text">Belum ada skor.</div>
        </div>

        <div class="info-box desktop-controls">
          <h3>KONTROL</h3>
          <p class="controls-text">Gunakan Mouse atau Tombol Panah untuk bergerak.</p>
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
  position: absolute; top: 1.5rem; left: 1.5rem;
  padding: 0.6rem 1.2rem; font-size: 0.9rem; font-weight: 600;
  color: var(--text-secondary, #a0a0a0);
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 8px; text-decoration: none;
  transition: all 0.2s ease-in-out;
  z-index: 10;
}
.back-button:hover { background-color: #2c3e50; color: #fff; }

.breakout-card {
  display: flex; flex-direction: column; gap: 2rem;
  width: 100%; max-width: 1200px;
}
.game-main { flex: 3; }

h1 {
  font-size: 2.5rem; font-weight: 700;
  color: var(--accent-color, #e94560);
  text-align: center; margin-bottom: 1rem;
}

.stats {
  display: flex; justify-content: space-between;
  margin-bottom: 1rem; font-size: 1.2rem; font-weight: 600;
}
.lives { display: flex; align-items: center; gap: 0.2rem; }
.heart { color: #ff1744; animation: heart-beat 1.5s infinite ease-in-out; }
@keyframes heart-beat {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

.game-area {
  width: 100%;
  cursor: pointer;
}
.game-board {
  width: 100%;
  border-radius: 8px;
  border: 2px solid var(--border-color, rgba(224, 224, 224, 0.2));
  box-shadow: 0 0 20px rgba(0,0,0,0.5);
}

.glow-element {
  filter: url(#glow);
}

.game-message {
  font-family: 'Poppins', sans-serif;
  font-size: 50px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 2px;
  fill: #ffffff;
}

.mobile-slider-control {
  display: block;
  margin-top: 1.5rem;
  padding: 1rem;
  background-color: var(--bg-card, #16213e);
  border-radius: 8px;
}
.slider-track {
  width: 100%;
  height: 10px;
  background-color: var(--bg-color-deep, #10101a);
  border-radius: 5px;
  position: relative;
}
.slider-thumb {
  position: absolute;
  height: 24px;
  background-color: var(--accent-color, #e94560);
  border-radius: 12px;
  top: 50%;
  transform: translateY(-50%);
  border: 2px solid #fff;
}

.info-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2rem; 
}

.info-box {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 12px;
  padding: 1rem;
}

.info-box h3 {
  font-size: 1.1rem; font-weight: 600; margin: 0 0 1rem 0;
  padding-bottom: 0.5rem; text-align: center;
  border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  color: var(--accent-color, #e94560);
}

.leaderboard-box h3 {
  margin-top: 0; 
}

.leaderboard-list {
  list-style: none; padding: 0; margin: 0; text-align: left;
}
.leaderboard-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
}
.leaderboard-item:last-child { border-bottom: none; }
.player-info { display: flex; align-items: center; gap: 1rem; }
.rank { font-weight: 700; font-size: 1.2rem; min-width: 35px; }
.player-name { font-weight: 600; }
.score-value { font-weight: 700; font-size: 1.2rem; }
.loading-text { color: var(--text-secondary, #a0a0a0); text-align: center; }

.desktop-controls {
  display: none;
  text-align: center;
}
.controls-text {
  padding: 1rem 0.5rem;
  font-size: 1.1rem;
  font-weight: 500;
  color: var(--text-primary, #e0e0e0);
  line-height: 1.6;
}

@media (min-width: 992px) {
  .page-container {
    align-items: center;
    padding: 1.5rem;
  }
  .breakout-card {
    flex-direction: row;
    align-items: flex-start;
  }
  .mobile-slider-control {
    display: none;
  }
  .desktop-controls {
    display: block;
  }
}
</style>