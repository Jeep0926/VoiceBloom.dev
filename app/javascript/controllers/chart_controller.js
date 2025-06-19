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
    data: Array
  }

  connect() {
    this.renderChart();
  }

  renderChart() {
    if (!this.hasCanvasTarget || !this.hasDataValue) {
      console.error("Chart canvas target or data value is missing!");
      return;
    }

    // data-chart-data-value から渡されたデータを使用
    const chartData = this.dataValue;

    // データを各配列に分解
    const labels = chartData.map(d => d.date);
    const pitchData = chartData.map(d => d.pitch);
    const tempoData = chartData.map(d => d.tempo);
    const volumeData = chartData.map(d => d.volume);

    new Chart(this.canvasTarget, {
      type: 'line', // 折れ線グラフ
      data: {
        labels: labels,
        datasets: [
          {
            label: '声の高さ',
            data: pitchData, // 整形したデータを使用
            borderColor: 'rgba(128, 90, 213, 1)', // 紫
            backgroundColor: 'rgba(128, 90, 213, 0.1)',
            tension: 0.4, // 曲線を滑らかに
            yAxisID: 'y',
          },
          {
            label: '話す速さ',
            data: tempoData, // 整形したデータを使用
            borderColor: 'rgba(239, 68, 68, 1)', // 赤
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            tension: 0.4,
            yAxisID: 'y',
          },
          {
            label: '声の音量',
            data: volumeData, // 整形したデータを使用
            borderColor: 'rgba(34, 197, 94, 1)', // 緑
            backgroundColor: 'rgba(34, 197, 94, 0.1)',
            tension: 0.4,
            yAxisID: 'y',
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100, // スコアや指標の最大値に合わせて調整
          },
          x: {
            grid: {
              display: false // 縦のグリッド線を非表示に
            }
          }
        },
        plugins: {
          legend: {
            position: 'bottom', // 凡例を下に
            labels: {
              usePointStyle: true, // ポイントのスタイルを凡例に使う
              pointStyle: 'circle', // ポイントのスタイルを円形に
              padding: 20 // 凡例間のパディング
            }
          }
        }
      }
    });
  }
}