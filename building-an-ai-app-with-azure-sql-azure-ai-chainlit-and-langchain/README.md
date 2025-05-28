# Building an AI App with Azure SQL, Azure AI, Chainlit and LangChain

This folder contains code for Video: Building an AI App with Azure SQL, Azure AI, Chainlit and LangChain.

Video Link: [Building an AI App with Azure SQL, Azure AI, Chainlit and LangChain](https://youtu.be/xqSuHMZxFUA)

## Features
- Uses LangChain with Azure OpenAI (GPT-4o)
- Stores embeddings and does vector search in Azure SQL
- Provides memory-enabled chat using Chainlit
- Can answer follow-ups contextually

## Setup
1. Fill in your `.env` with:
   - Azure SQL connection string
   - Azure OpenAI key

2. Install dependencies:
```
pip install -r requirements.txt
```

3. Run the app:
```
chainlit run app.py
```
