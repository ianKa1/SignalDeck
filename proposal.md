Current Focus:
Decide Tech Stack
Then, decide roles

9. Initial MVP - Product Idea
Our hackathon MVP will demonstrate the complete workflow for one company being analyzed by a financial professional.
It will include:
Company intelligence profile: Input the company's business model, financial drivers, strategic objectives, competitors, and key assumptions.
External information collection: Use Bright Data to retrieve relevant information from a curated set of public sources.
Specialized research agents: Analyze competitive developments, market opportunities, and financial or regulatory risks.
Thesis-aware analyst: Connect the findings to company-specific financial drivers and strategic assumptions.
Urgent alerts: Identify high-priority developments using explicit materiality, confidence, and urgency criteria.
Daily intelligence briefing: Produce a concise, prioritized report with sources, implications, and suggested next steps.
Financial impact assessment: Where sufficient information exists, show illustrative scenario impacts on revenue, costs, margins, cash flow, or forecasts.
Analyst review interface: Allow the professional to validate findings, record feedback, and select which insights to incorporate into their advice.


The proposed stack
Base44 — Application and backend
Company profiles, dashboard, database, analyst review, server-side TypeScript functions, authentication and scheduling.
Bright Data
Find current external developments through search; retrieve relevant public webpages as structured or readable content.
Claude API
Extract events, assess financial relevance, connect evidence to company assumptions, and create structured briefings.
Base44 database
Persist sources, findings, financial scenarios, alerts, briefings, analyst feedback and processing history.

1. Technology selection
Layer
Technology
What we use it for
Frontend
Base44 app builder
Company setup, intelligence feed, alert cards, briefing and review screens
Backend
Base44 backend functions (TypeScript/Deno)
Run the research pipeline, call APIs, score events and save results
Database
Base44 entities
Store company profiles, source evidence, findings and feedback
Discovery
Bright Data SERP API
Discover relevant news articles, company announcements and industry sources
Page extraction
Bright Data Web Unlocker
Retrieve selected public webpages in Markdown or other supported formats
AI analysis
Claude API
Structured extraction, specialist analyses, synthesis and explanations
Scenario calculations
TypeScript functions
Calculate illustrative revenue, margin and cost impacts deterministically
Scheduling
Base44 Automations
Trigger regular monitoring and daily briefings
Notifications
Base44 email integration or in-app dashboard
Display urgent alerts and deliver briefings



Product Brief: AI-Powered Strategic Intelligence for Financial Analysts
Working name: SignalDesk
Product category: AI financial and strategic intelligence
Primary customer: Financial analysts and FP&A professionals
End users of the advice: Companies, CFOs, founders, and executive teams
Core delivery: Urgent intelligence alerts + daily client-specific briefings
Technology: Bright Data + Base44 + AI research and analysis agents
1. Executive summary
We are building an AI-powered strategic intelligence platform that helps financial analysts and FP&A professionals deliver better, faster, and more proactive advice to the companies they support.
The platform continuously monitors external developments across global news, industry publications, competitor announcements, regulatory sources, and other relevant public information. It evaluates those developments against a company's business model, strategic thesis, financial position, and objectives.
Rather than simply summarizing news, the system explains how new information could affect a company's revenue growth, costs, margins, competitive position, capital requirements, forecasts, and strategic opportunities.
A central AI analyst coordinates specialized research agents, evaluates evidence, identifies material developments, and produces actionable intelligence for the financial professional to review and incorporate into their advice.
Our goal is to turn financial analysts from reactive reporting professionals into proactive strategic advisers, supported by an always-on AI intelligence function.
2. Our product thesis
Financial analysts and FP&A professionals are increasingly expected to provide strategic advice, not merely explain historical financial performance.
To advise a company effectively, they need to understand both its internal financial position and the external environment influencing its future.
However, important information is scattered across news sources, competitor websites, regulatory announcements, industry research, and market developments. Analysts must manually identify relevant signals, assess their credibility, understand their financial implications, and determine whether they require a change in the company's forecast or strategy.
This process is time-consuming, difficult to perform continuously, and dependent on the individual analyst's research capacity.
Our thesis is that financial analysts can deliver materially better strategic advice when AI continuously monitors the external environment, connects new evidence to a company's financial and strategic assumptions, and translates important developments into quantified risks, opportunities, and recommended actions.
We believe the next generation of financial analysis will combine traditional financial modeling with continuous external intelligence.
3. Who we serve
Our primary market is the Financial Analysts and FP&A segment.
We are building for professionals who advise companies on financial performance, planning, business strategy, investment decisions, and resource allocation.
Our initial target customers include:
FP&A analysts and managers supporting CFOs and executive teams.
Fractional CFOs and outsourced finance advisory firms.
Financial and strategic analysts at consulting and advisory firms.
Corporate finance professionals advising growing businesses.
Financial planning teams that support multiple business units or clients.
Our initial ideal customer is a financial advisory professional or small FP&A team responsible for several companies or business units, with limited capacity to conduct continuous external research.
These professionals already understand financial models and business performance. What they need is a scalable way to understand what is changing outside the company and how those changes affect the numbers and decisions they advise on.
Our customer versus their client
We sell to the financial professional. That professional uses our platform to advise their company clients.
The analyst is the primary user, reviewer, and decision-maker. The company receives the resulting insights through the analyst's existing advisory relationship.
This distinction is central to our product design, distribution strategy, and value proposition.
4. What we are building
We are building an AI strategic intelligence analyst that works alongside financial professionals.
The product maintains a persistent intelligence profile for each company under analysis, including its:
Business model, revenue streams, cost structure, and financial position.
Strategic thesis, growth assumptions, and business objectives.
Customers, competitors, market segments, and distribution channels.
Financial forecasts, operating metrics, and critical dependencies.
Existing risks, potential opportunities, and upcoming decisions.
Using this context, the system monitors relevant external information and assesses how new developments could affect the company's financial outlook and strategic direction.
The product produces two core outputs:
Urgent alerts: Notifications about material developments that may require timely attention, investigation, or a change in the analyst's assessment.
Daily intelligence briefings: Prioritized summaries of external developments, their implications for the company, potential financial effects, and suggested next steps for the analyst.
Every significant finding includes source references, supporting evidence, assumptions, confidence, and a clear distinction between observed facts and analytical interpretations.
5. How the AI analyst works
A. Understand the company
The analyst establishes a structured company thesis, capturing the business's objectives, financial drivers, strategic assumptions, and principal risks.
For example, a company may expect revenue to grow through expansion into a new customer segment, while assuming that customer acquisition costs remain stable.
The AI analyst records these assumptions and identifies external developments that could support or challenge them.
B. Monitor external information
Using Bright Data and appropriate source-specific collection methods, the platform gathers relevant information from public news, company announcements, industry publications, regulatory sources, and competitor websites.
The monitoring system identifies developments involving:
Competitive launches, pricing changes, funding, acquisitions, and partnerships.
Changes in customer demand, industry growth, and market structure.
Emerging technologies and potential substitutes.
Regulatory, political, and geopolitical developments.
Supplier, distribution, and supply-chain changes.
Industry economics, financing conditions, and capital allocation trends.
Monitoring is customized to the company being analyzed, rather than relying solely on generic keyword alerts.
C. Deploy specialist agents
A central AI analyst delegates research tasks to specialized agents covering competition, market opportunities, regulatory developments, customer and industry trends, and operational or financial risks.
Each agent returns structured findings, supporting sources, potential implications, and unresolved questions.
The central analyst consolidates those findings, removes duplicates, evaluates conflicting evidence, and determines which developments matter to the company's financial and strategic outlook.
D. Translate external developments into financial implications
This is the core of our product.
The system should connect external events to specific financial drivers and planning assumptions wherever sufficient evidence is available.
For example:
A competitor reduces pricing, potentially affecting the company's pricing power, revenue assumptions, or gross margins.
A new regulation creates compliance costs or changes the addressable market.
A new technology creates an opportunity to reduce operating costs or develop a product offering.
A major customer announces a change in purchasing behavior, potentially affecting sales forecasts.
A supplier disruption introduces a risk to production, delivery schedules, or working capital.
The system should identify which financial assumptions merit review and quantify scenario impacts when the necessary data and calculation methods are available.
It must not present speculative financial impacts as established facts.
E. Deliver actionable intelligence
The analyst receives a prioritized briefing showing:
What happened and when.
Why it matters to the company.
Which financial drivers, forecasts, or strategic assumptions may be affected.
What evidence supports the assessment.
How confident the system is and what remains uncertain.
What the financial professional should investigate or consider doing next.
The financial professional validates the analysis and incorporates relevant findings into forecasts, client discussions, management reports, and strategic recommendations.
6. Our differentiation
AI-powered market research and competitive intelligence are already established product categories. AlphaSense, for example, offers financial intelligence, competitive monitoring, company research, and AI-powered analysis.
We are not attempting to compete simply by collecting more news, producing longer summaries, or deploying more AI agents.
Our differentiation is connecting external intelligence to the financial analyst's company-specific advisory workflow.
Traditional research and monitoring
Our product vision
Monitors companies, topics, and keywords
Monitors developments against a company's strategic and financial thesis
Summarizes external information
Explains how evidence may affect financial drivers and business assumptions
Produces alerts and research reports
Identifies implications for forecasts, margins, costs, cash flow, and growth
Leaves analysts to connect research to models
Highlights which assumptions and financial scenarios may need reassessment
Provides point-in-time research
Maintains a continuous record of evolving risks, opportunities, and supporting evidence
Helps users understand what happened
Helps financial professionals determine what to investigate, model, and advise on next

We must validate the extent to which existing platforms already support these connected workflows. Our differentiation should be demonstrated through better financial relevance, prioritization, and analyst productivity—not asserted on the basis of AI alone.
7. Our core value proposition
For financial analysts and FP&A professionals:
Spend less time monitoring the world and more time advising companies on what it means for their financial future.
We aim to help our customers:
Identify important opportunities and risks earlier.
Deliver more proactive and differentiated advice.
Incorporate relevant external developments into financial forecasts and scenarios.
Reduce manual research and information-processing time.
Support recommendations with traceable evidence.
Monitor more companies and strategic issues without proportionally increasing research workload.
For the companies receiving advice, the expected benefit is better-informed decisions, earlier identification of material developments, and more context-aware financial planning.
8. Product design principles
Financial relevance first. A news event matters only if it could materially affect the company's performance, risk, or strategic direction.
Evidence-backed analysis. Important claims must be linked to verifiable sources and clearly distinguished from interpretations and hypotheses.
Financial quantification where possible. Translate developments into scenarios and financial implications when reliable inputs and defensible calculation methods are available.
Analyst in control. The product supports professional judgment rather than autonomously issuing definitive financial or strategic advice.
Continuous learning about the company. Maintain a persistent company thesis and update research priorities when the company's objectives or assumptions change.
Low noise, high signal. Prioritize material, actionable findings instead of overwhelming users with generic alerts.
Contradictory evidence matters. Actively identify information that challenges the existing company thesis rather than simply confirming it.
9. Initial MVP
Our hackathon MVP will demonstrate the complete workflow for one company being analyzed by a financial professional.
It will include:
Company intelligence profile: Input the company's business model, financial drivers, strategic objectives, competitors, and key assumptions.
External information collection: Use Bright Data to retrieve relevant information from a curated set of public sources.
Specialized research agents: Analyze competitive developments, market opportunities, and financial or regulatory risks.
Thesis-aware analyst: Connect the findings to company-specific financial drivers and strategic assumptions.
Urgent alerts: Identify high-priority developments using explicit materiality, confidence, and urgency criteria.
Daily intelligence briefing: Produce a concise, prioritized report with sources, implications, and suggested next steps.
Financial impact assessment: Where sufficient information exists, show illustrative scenario impacts on revenue, costs, margins, cash flow, or forecasts.
Analyst review interface: Allow the professional to validate findings, record feedback, and select which insights to incorporate into their advice.
Base44 will provide the application interface and core workflow. Bright Data will support external information collection. Backend functions will coordinate ingestion, research, analysis, persistence, and scheduled delivery.
The initial MVP will prioritize a small number of reliable sources, a clear company profile, and high-quality analysis over broad but shallow coverage.
10. How we measure success
Our primary measure of success is whether the product improves the financial professional's ability to provide useful advice.
We will initially measure:
Relevance: The proportion of findings that analysts consider material to their client.
Novelty: The frequency with which the product surfaces developments the analyst had not already identified.
Actionability: The proportion of findings that lead to further investigation, a forecast review, or a client recommendation.
Research efficiency: Time saved in monitoring, researching, and preparing client briefings.
Evidence quality: Accuracy, source reliability, and traceability of material claims.
Financial usefulness: Whether insights identify assumptions or scenarios worth revisiting.
Retention: Whether analysts use the platform repeatedly as part of their client advisory workflow.
Early validation should involve a small group of financial professionals using the product on real or appropriately sanitized company cases over several weeks.
11. Long-term vision
Our long-term vision is to become the external intelligence layer for financial analysis and corporate advisory.
Over time, the product could connect public developments with internal financial models, forecasts, historical results, and strategic plans.
This would allow the analyst to move from discovering an external event to understanding its possible impact on a company's financial outlook, comparing scenarios, and preparing an evidence-backed recommendation.
The result would be an intelligence system that helps financial professionals provide continuous, forward-looking advice rather than relying primarily on periodic reporting and manual research.
Product thesis in one sentence
We are building an AI-powered strategic intelligence copilot for financial analysts and FP&A professionals that continuously monitors the external world, connects material developments to a company's financial and strategic assumptions, and helps analysts deliver faster, more proactive, evidence-backed advice through urgent alerts and daily briefings
