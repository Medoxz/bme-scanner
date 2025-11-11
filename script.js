// Load ZXing library from CDN dynamically (like in the example)
const zxingScript = document.createElement('script');
document.head.appendChild(zxingScript);

window.addEventListener('load', function () {
  let selectedDeviceId;
  const codeReader = new ZXing.BrowserMultiFormatReader()
  console.log('ZXing code reader initialized')

  const video = document.getElementById('video')
  const resultEl = document.getElementById('result')
  const startBtn = document.getElementById('startBtn')
  const cameraSelect = document.getElementById('cameraSelect')

  codeReader.listVideoInputDevices()
    .then((videoInputDevices) => {
      selectedDeviceId = videoInputDevices[0].deviceId

      startBtn.addEventListener('click', () => {
        // resultEl.textContent = 'Scanning...'
        codeReader.decodeFromVideoDevice(selectedDeviceId, 'video', (result, err) => {
          if (result) {
            console.log(result);
            resultEl.textContent = result.text;
          }
          if (err && !(err instanceof ZXing.NotFoundException)) {
            console.error(err);
            resultEl.textContent = `Error: ${err}`
          }
        });
        console.log(`Started continuous decode from camera with id ${selectedDeviceId}`)
      });

      document.getElementById('resetBtn').addEventListener('click', () => {
        codeReader.reset()
        console.log('Reset.')
      })


      // Populate the camera selection dropdown
      // cameraSelect.innerHTML = '';
      // if (videoInputDevices.length === 0) {
      //   resultEl.textContent = 'No cameras found';
      //   return;
      // }

      if (videoInputDevices.length >= 1) {
        videoInputDevices.forEach((device, index) => {
            const option = document.createElement('option');
            option.text = device.label || `Camera ${index + 1}`;
            option.value = device.deviceId;
            cameraSelect.appendChild(option);
        });

        cameraSelect.onchange = () => {
          selectedDeviceId = cameraSelect.value;
        };
      }

      



      

    })
    .catch((err) => {
      console.error(err);
      resultEl.textContent = `Camera error: ${err.message}`;
    })
})

// Register service worker for PWA installability
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('service-worker.js');
}