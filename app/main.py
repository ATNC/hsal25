from fastapi import FastAPI, HTTPException
import httpx

app = FastAPI()

API_URL = 'https://bank.gov.ua/NBUStatService/v1/statdirectory/dollar_info?json'

# health check
@app.get('/')
async def health_check():
    return {'status': 'ok'}

@app.get('/uah-to-usd')
async def get_uah_to_usd():
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(API_URL)
            if response.status_code != 200:
                raise HTTPException(status_code=500, detail='Error retrieving exchange rate')
            data = response.json()
            uah_to_usd = data[0]['rate']
            return {'UAH to USD': uah_to_usd}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8000)