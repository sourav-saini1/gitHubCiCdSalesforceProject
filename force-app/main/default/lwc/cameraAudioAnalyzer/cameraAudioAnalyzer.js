import { LightningElement, track } from 'lwc';

export default class CameraAudioAnalyzer extends LightningElement {
    @track transcript = '';
    @track emoji = '😐';
    recognition;
_recognition;



   connectedCallback() {

      //https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
      //https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API/Using_the_Web_Speech_API
      //Browsers currently support speech recognition with prefixed properties. Therefore at the start of our code we include these lines to allow for both prefixed properties and unprefixed versions that may be supported in future:
      window.SpeechRecognition = window.webkitSpeechRecognition || window.SpeechRecognition;
      if ("SpeechRecognition" in window) {
         this._recognition = new webkitSpeechRecognition() || new SpeechRecognition();
         this._recognition.lang = 'en-US';
         this._recognition.continuous = true;

      }
        console.log('Inside Connected call back: ');

   }



   get speechToTextDataFound() {
      return this._speechDBResults.length > 0 ? true : false;
   }



   handleClick(event) {
      this._recognition.start();
      //When a result has been successfully recognized, the result event fires
      this._recognition.onresult = (event) => {
         const msg = event.results[0][0].transcript;
         this.handleSpeechRecognized(msg);
      }
   }

   //Extract the text results and add it to the Chatter.
   handleSpeechRecognized(msg) {
 console.log('OUTPUT : ');
 console.log('msg : ',msg);
      this.transcript = msg;

        //  this.handleKeyChange(msg);

   }

      handleClickToStop(event) {

      this._recognition.abort();
      console.log("Speech recognition has stopped.");
   }


    // 📸 EMOTION DETECTION
    async loadFaceApiModels() {
        // Promise.all([
        //     faceapi.nets.tinyFaceDetector.loadFromUri('/resource/faceapi_models'),
        //     faceapi.nets.faceExpressionNet.loadFromUri('/resource/faceapi_models')
        // ]).then(() => {
        //     this.startVideo();
        // });

                    this.startVideo();

    }

    startVideo() {
        navigator.mediaDevices.getUserMedia({ video: true })
            .then((stream) => {
                this.videoStream = stream;
                const video = this.template.querySelector('video');
                video.srcObject = stream;
                video.addEventListener('playing', () => this.detectExpression(video));
            })
            .catch((err) => {
                console.error('Error accessing camera', err);
            });
    }

    async detectExpression(video) {
        setInterval(async () => {
            const detection = await faceapi
                .detectSingleFace(video, new faceapi.TinyFaceDetectorOptions())
                .withFaceExpressions();

            if (detection && detection.expressions) {
                const emotion = Object.keys(detection.expressions)
                    .reduce((a, b) => detection.expressions[a] > detection.expressions[b] ? a : b);
                this.emoji = this.getEmoji(emotion);
            }
        }, 1500);
    }

    getEmoji(emotion) {
        switch (emotion) {
            case 'happy': return '😄';
            case 'sad': return '😢';
            case 'angry': return '😡';
            case 'surprised': return '😲';
            case 'disgusted': return '🤢';
            case 'fearful': return '😨';
            default: return '😐';
        }
    }

    disconnectedCallback() {
        if (this.videoStream) {
            this.videoStream.getTracks().forEach(track => track.stop());
        }
    }
}