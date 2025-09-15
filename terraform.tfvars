// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0



# Sample Values, modify accordingly

knowledge_base_name                 = "bedrock-kb"
enable_access_logging               = true
enable_s3_lifecycle_policies        = true
enable_endpoints                    = false
knowledge_base_model_id             = "amazon.titan-embed-g1-text-02:0"
app_name                            = "acme"
env_name                            = "prod"
app_region                          = "usw1"
agent_model_id                      = "amazon.titan-text-express-v1:0"
agent_name                          = "bedrock-agent"
agent_alias_name                    = "bedrock-agent-alias"
agent_action_group_name             = "bedrock-agent-ag"
aoss_collection_name                = "aoss-collection"
aoss_collection_type                = "VECTORSEARCH"
agent_instructions                  = <<-EOT
You are a versatile AI assistant designed to help with a wide range of tasks. You have access to various tools and a knowledge base to provide comprehensive assistance.

Your capabilities include:
- General office tasks (scheduling, organization, productivity)
- Fact-finding with reliable sources and citations
- Web search capabilities for current information
- Coding assistance (debugging, best practices, code review)
- General knowledge and problem-solving

Guidelines:
1. Use the knowledge base for factual information and detailed explanations
2. Use tools for calculations, data processing, or specific actions
3. Always cite sources when providing factual information
4. Be helpful, accurate, and professional in all responses
5. If you don't have specific information, suggest where to find it
6. For coding tasks, provide clear explanations and best practices

Choose the appropriate tool or knowledge base based on the user's request. If multiple approaches are valid, explain your reasoning for the chosen method.
EOT
agent_description                   = "A versatile AI assistant for office tasks, research, web search, and coding help"
agent_actiongroup_descrption        = "Use the action group for calculations, data processing, web search, and specialized tasks"
kb_instructions_for_agent           = "Use the knowledge base for factual information, research, coding best practices, and detailed explanations. Always cite sources and provide context."
code_base_zip                       = "placeholder.zip"
enable_guardrails                   = false
guardrail_name                      = "bedrock-guardrail"
guardrail_blocked_input_messaging   = "This input is not allowed due to content restrictions."
guardrail_blocked_outputs_messaging = "The generated output was blocked due to content restrictions."
guardrail_description               = "A guardrail for Bedrock to ensure safe and appropriate content"
guardrail_content_policy_config = [
  {
    filters_config = [
      {
        input_strength  = "MEDIUM"
        output_strength = "MEDIUM"
        type            = "HATE"
      },
      {
        input_strength  = "HIGH"
        output_strength = "HIGH"
        type            = "VIOLENCE"
      }
    ]
  }
]
guardrail_sensitive_information_policy_config = [
  {
    pii_entities_config = [
      {
        action = "BLOCK"
        type   = "NAME"
      },
      {
        action = "BLOCK"
        type   = "EMAIL"
      }
    ],
    regexes_config = [
      {
        action      = "BLOCK"
        description = "Block Social Security Numbers"
        name        = "SSN_Regex"
        pattern     = "^\\d{3}-\\d{2}-\\d{4}$"
      }
    ]
  }
]
guardrail_topic_policy_config = [
  {
    topics_config = [
      {
        name       = "investment_advice"
        examples   = ["Where should I invest my money?", "What stocks should I buy?"]
        type       = "DENY"
        definition = "Any advice or recommendations regarding financial investments or asset allocation."
      }
    ]
  }
]
guardrail_word_policy_config = [
  {
    managed_word_lists_config = [
      {
        type = "PROFANITY"
      }
    ],
    words_config = [
      {
        text = "badword1"
      },
      {
        text = "badword2"
      }
    ]
  }
]
