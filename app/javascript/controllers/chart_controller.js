import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from 'chart.js';
import 'chartjs-adapter-date-fns'; // 日付アダプタをインポート

Chart.register(...registerables); // Chart.jsの全ての機能を登録

export default class extends Controller {
  static targets = [ "canvas" ]
  // ビューからJSON形式のデータを受け取るためのValue
  static values = {
    pitch: Array,
    tempo: Array,
    volume: Array,
    data: Array,
    chartType: String // 'condition' or 'practiceScore' のようなタイプを想定
  }

  connect() {
    // データを元に、グラフのオプションとデータセットを動的に構築
    const chartConfig = this.buildChartConfig();
    if (!chartConfig) return;

    if (this.hasCanvasTarget) {
      new Chart(this.canvasTarget, chartConfig);
    }
  }

  // グラフ設定を構築するメソッド
  buildChartConfig() {
    if (!this.hasDataValue || this.dataValue.length === 0) return null;

    // グラフタイプに応じて設定を切り替える
    if (this.chartTypeValue === 'practiceScore') {
      return this.practiceScoreChartConfig();
    } else {
      // デフォルトは声のコンディショングラフ
      return this.conditionChartConfig();
    }
  }
  
  // 発声練習スコア推移グラフ用の設定
  practiceScoreChartConfig() {
    const labels = this.dataValue.map(d => d.date);
    const scoreData = this.dataValue.map(d => d.score);

    return {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: '総合スコア',
          data: scoreData,
          borderColor: 'rgba(128, 90, 213, 1)', // 紫
          backgroundColor: 'rgba(128, 90, 213, 0.1)',
          tension: 0.4,
          yAxisID: 'y',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 500 // ★ Y軸の最大値を500に設定
          },
          x: { grid: { display: false } }
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: { usePointStyle: true, pointStyle: 'circle', padding: 20 }
          }
        }
      }
    };
  }

  // 声のコンディショングラフ用の設定
  conditionChartConfig() {
    const labels = this.dataValue.map(d => d.date);
    const pitchData = this.dataValue.map(d => d.pitch);
    const tempoData = this.dataValue.map(d => d.tempo);
    const volumeData = this.dataValue.map(d => d.volume);

    return {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          { label: '声の高さ', data: pitchData, borderColor: 'rgba(128, 90, 213, 1)', /* ... */ },
          { label: '話す速さ', data: tempoData, borderColor: 'rgba(239, 68, 68, 1)', /* ... */ },
          { label: '声の音量', data: volumeData, borderColor: 'rgba(34, 197, 94, 1)', /* ... */ }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100 // ★ Y軸の最大値を100に設定
          },
          x: { grid: { display: false } }
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: { usePointStyle: true, pointStyle: 'circle', padding: 20 }
          }
        }
      }
    };
  }
}