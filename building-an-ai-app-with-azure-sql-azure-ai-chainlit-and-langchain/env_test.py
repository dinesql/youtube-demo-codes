import os
from dotenv import load_dotenv

load_dotenv()

print("API KEY:", os.getenv("AZURE_OPENAI_API_KEY"))
