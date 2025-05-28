import chainlit as cl
from langchain.chat_models import AzureChatOpenAI
from langchain.agents import initialize_agent, AgentType, Tool
from langchain.memory import ConversationBufferMemory
from langchain.schema import SystemMessage
from sql_utils import get_matching_products
import os

from dotenv import load_dotenv
load_dotenv()

# Define tool for product search
def product_search_tool(input_text: str):
    results = get_matching_products(input_text)
    if not results:
        return "Sorry, no matching products found."
    #response = "Here are some matching products:\n"
    response = ""

    for p in results:
        response += f"- {p['ProductName']} (${p['Price']}): {p['Details']}\n"
    
    prompt = f"You're a helpful assistant. Rephrase the following product list into a friendly recommendation message:\n\n{response}"
    try:
        rephrased = llm.predict(prompt)
        return rephrased
    except Exception as e:
        print("Error during GPT rephrasing:", e)
        return response  # Fallback to original
    

tools = [
    Tool(
        name="product_search",
        func=product_search_tool,
        description="Use this to search for product recommendations based on user input."
    )
]

# https://dinesqlopenai.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=2025-01-01-preview

# Initialize LLM
llm = AzureChatOpenAI(
    deployment_name="gpt-4",  # Replace with your actual deployment name
    model="gpt-4o",
    openai_api_base="https://dinesqlopenai.openai.azure.com/",
    openai_api_version="2025-01-01-preview", 
    openai_api_key=os.getenv("AZURE_OPENAI_API_KEY")
)

# Memory to keep track of conversation
memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)

# Initialize agent
agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent=AgentType.OPENAI_FUNCTIONS,
    memory=memory,
    verbose=True
)

@cl.on_message
async def on_message(message: cl.Message):
    response = agent.run(message.content)
    await cl.Message(content=response).send()
