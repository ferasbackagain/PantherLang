from compiler.ai import (
    AIProvider,
    Agent,
    AnthropicProvider,
    Document,
    EmbeddingProvider,
    GeminiProvider,
    OllamaProvider,
    OpenAIProvider,
    OpenRouterProvider,
    RAGEngine,
    Tool,
    ToolCall,
    VectorStore,
)
from compiler.ai.providers import CompletionResult, Message


def test_openai_provider_mock():
    provider = OpenAIProvider(api_key="", model="gpt-4o")
    result = provider.complete([Message(role="user", content="hello")])
    assert "[mock]" in result.content
    assert result.model == "gpt-4o"


def test_anthropic_provider_mock():
    provider = AnthropicProvider(api_key="", model="claude-sonnet-4-20250514")
    result = provider.complete([Message(role="user", content="hello")])
    assert "[mock]" in result.content


def test_gemini_provider_mock():
    provider = GeminiProvider(api_key="", model="gemini-2.0-flash")
    result = provider.complete([Message(role="user", content="hello")])
    assert "[mock]" in result.content


def test_ollama_provider_mock():
    provider = OllamaProvider(model="llama3")
    result = provider.complete([Message(role="user", content="hello")])
    assert "[mock]" in result.content


def test_openrouter_provider_mock():
    provider = OpenRouterProvider(api_key="", model="openai/gpt-4o")
    result = provider.complete([Message(role="user", content="hello")])
    assert "[mock]" in result.content


def test_ai_provider_interface():
    provider = AIProvider()
    try:
        provider.complete([])
        assert False, "should raise"
    except NotImplementedError:
        pass
    try:
        provider.embed("")
        assert False, "should raise"
    except NotImplementedError:
        pass


def test_tool_dataclass():
    tool = Tool(name="echo", description="echoes input", fn=lambda x: x)
    assert tool.name == "echo"
    assert tool.description == "echoes input"


def test_tool_call_dataclass():
    tc = ToolCall(tool_name="echo", arguments={"x": "hello"}, result="hello")
    assert tc.tool_name == "echo"
    assert tc.arguments == {"x": "hello"}
    assert tc.result == "hello"


def test_agent_create():
    provider = OpenAIProvider()
    agent = Agent(provider, system_prompt="You are helpful.")
    assert agent is not None


def test_agent_run_mock():
    provider = OpenAIProvider()
    agent = Agent(provider)
    result = agent.run("say hello")
    assert result is not None
    assert len(result) > 0


def test_agent_reset():
    provider = OpenAIProvider()
    agent = Agent(provider, system_prompt="System")
    agent.run("test")
    assert len(agent.history) >= 2
    agent.reset()
    assert len(agent.history) <= 1


def test_agent_with_tool():
    provider = OpenAIProvider()
    agent = Agent(provider)
    agent.register_tool(Tool(name="greet", description="greets", fn=lambda name: f"Hello, {name}!"))
    result = agent.run("greet me")
    assert result is not None


def test_vector_store_add_and_search():
    store = VectorStore()
    doc1 = Document(text="Panther is a programming language", embedding=[1.0, 0.0])
    doc2 = Document(text="Python is a programming language", embedding=[0.0, 1.0])
    store.add(doc1)
    store.add(doc2)
    assert store.count == 2
    results = store.search([1.0, 0.1], top_k=1)
    assert len(results) == 1
    assert "Panther" in results[0][0].text


def test_vector_store_empty_search():
    store = VectorStore()
    results = store.search([1.0, 0.0])
    assert results == []


def test_vector_store_cosine_similarity():
    sim = VectorStore._cosine_similarity([1.0, 0.0], [1.0, 0.0])
    assert abs(sim - 1.0) < 0.001
    sim2 = VectorStore._cosine_similarity([1.0, 0.0], [0.0, 1.0])
    assert abs(sim2 - 0.0) < 0.001


def test_vector_store_save_load(tmp_path):
    store = VectorStore()
    store.add(Document(text="test doc", embedding=[0.5, 0.5]))
    path = str(tmp_path / "vectors.json")
    store.save(path)
    store2 = VectorStore()
    store2.load(path)
    assert store2.count == 1
    assert store2._documents[0].text == "test doc"


def test_rag_engine_create():
    provider = OpenAIProvider()
    rag = RAGEngine(provider)
    assert rag.store is not None
    assert rag.store.count == 0


def test_rag_engine_query():
    provider = OpenAIProvider()
    rag = RAGEngine(provider)
    rag.store.add(Document(text="PantherLang is a programming language.", embedding=[1.0, 0.0, 0.0]))
    result = rag.query("What is PantherLang?")
    assert result is not None


def test_embedding_provider_interface():
    provider = OpenAIProvider(api_key="", model="gpt-4o")
    ep = EmbeddingProvider(provider)
    embedding = ep.embed("test")
    assert isinstance(embedding, list)
    assert len(embedding) > 0
    assert all(isinstance(v, float) for v in embedding)


def test_document_dataclass():
    doc = Document(text="hello", metadata={"source": "test"}, embedding=[1.0])
    assert doc.text == "hello"
    assert doc.metadata == {"source": "test"}
    assert doc.embedding == [1.0]


def test_message_dataclass():
    msg = Message(role="user", content="hello")
    assert msg.role == "user"
    assert msg.content == "hello"


def test_completion_result_dataclass():
    cr = CompletionResult(content="response", model="gpt-4o", usage={"prompt_tokens": 10})
    assert cr.content == "response"
    assert cr.model == "gpt-4o"
    assert cr.usage == {"prompt_tokens": 10}
