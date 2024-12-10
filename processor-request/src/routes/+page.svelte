<script lang='ts'>
  import { onMount } from 'svelte'
  import { Alert, Dropzone, Label, Indicator, Input } from 'flowbite-svelte'
  
  enum Color { red='red', yellow='yellow', green='green' }

  const requestTarget: string = 'http://localhost:5001/predict'

  type PredictionRequestResponse = {
    'timestamp': string
  } & ({
    status: 'ok'
    result: 'angry' | 'contempt' | 'disgust' | 'fear' | 'happy' | 'neutral' | 'sad' | 'surprise'
    confidence: number
    message: string
  } | {
    status: 'error'
    message: string
  })
  
  let predictionResult: PredictionRequestResponse | undefined = undefined

  // Check server is alive
  let lastHeartbeat: Date = new Date('2002-01-24T04:00:00Z')
  let isAliveIndicatorColor: Color = Color.yellow

  const checkHeartbeat = () => {
    fetch(requestTarget)
      .then(response => {
        if (response.ok) {
          lastHeartbeat = new Date()
          isAliveIndicatorColor = Color.green
        } else {
          isAliveIndicatorColor = Color.red
        }
      })
      .catch(error => {
        isAliveIndicatorColor = Color.red
      })
    const now = new Date()
    const diff = now.getTime() - lastHeartbeat.getTime()
    if (diff > 1000 * 60 * 5) {
      isAliveIndicatorColor = Color.red
    } else {
      isAliveIndicatorColor = Color.green
    }
  }
  
  // Dropzone
  interface ImageFile {
    name: string
    base64: string
  }
  const convertToBase64 = async (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => {
        if (typeof reader.result === 'string') {
          // Remove the data URL prefix (data:image/jpegbase64,)
          const base64String = reader.result.split(',')[1]
          resolve(base64String)
        }
      }
      reader.onerror = reject
      reader.readAsDataURL(file)
    })
  }

  // Modify your dropzone handler
  let value: ImageFile | undefined = undefined
  const handleDrop = async (event: DragEvent) => {
    event.preventDefault()

    if (event.dataTransfer?.files) {
      const files = [...event.dataTransfer.files]
      for (const file of files) {
        // Check if file is an image
        if (file.type.startsWith('image/')) {
          try {
            const base64String = await convertToBase64(file)
            value = { name: file.name, base64: base64String }
            requestPrediction(value)
          } catch (error) {
            console.error('Error converting image to base64:', error)
          }
        } else {
          console.warn('File is not an image:', file.name)
        }
      }
    }
  }

  const requestPrediction = async (image: ImageFile) => {
    console.log('Sending image to server...')

    const response = await fetch(requestTarget, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        image: image.base64
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const result: PredictionRequestResponse = await response.json()
    // Handle the prediction result here
    console.log('Prediction:', result)
    predictionResult = result
  }

  const handleChange = async (event: Event) => {
    const target = event.target as HTMLInputElement
    if (target && target.files && target.files.length > 0) {
      const file = target.files[0]
      if (file.type.startsWith('image/')) {
        const base64String = await convertToBase64(file)
        value = { name: file.name, base64: base64String }
        requestPrediction(value)
      }
    }
  }

  onMount(() => {
    checkHeartbeat()
    setInterval(checkHeartbeat, 1000 * 10)
  })
</script>

<div class="p-8">
  <div class="mt-6 mb-6">
    <Label for="default-input" class="block mb-2">
      Request Target 
      <Indicator color={isAliveIndicatorColor} size='sm' class='inline-block' />
    </Label> 
    <Input id="default-input" placeholder="Default input" value={requestTarget} />
  </div>
  <div class="mt-6 mb-6">
    <Label for="file-input" class="block mb-2"></Label>
    <Dropzone
      id='dropzone'
      on:drop={handleDrop}
      on:dragover={(event) => {
        event.preventDefault()
      }}
      on:change={handleChange}>
      <svg aria-hidden="true" class="mb-3 w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" /></svg>
      {#if value === undefined}
        <p class="mb-2 text-sm text-gray-500 dark:text-gray-400"><span class="font-semibold">Click to upload</span> or drag and drop</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">SVG, PNG, JPG or GIF</p>
      {:else}
        <p>{value.name}</p>
      {/if}
    </Dropzone>
  </div>
  <div class="mt-6 mb-6">
  {#if predictionResult}
    {#if predictionResult['status'] === 'ok'}
      <Alert color='green'>
        <span class="font-medium">Prediction result:</span>
        {predictionResult['result']} ({Number(predictionResult['confidence']).toFixed(2)})
      </Alert>
    {:else if predictionResult['status'] === 'error'}
      <Alert>
        <span class="font-medium">Error:</span>
        {predictionResult['message']}
      </Alert>
    {/if}
  {/if}
  </div>
</div>
