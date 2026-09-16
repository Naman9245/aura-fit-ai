from fastapi import APIRouter, Depends, File, UploadFile

from app.deps import get_current_user

from app.schemas import ChatRequest, ChatResponse, MealScanResponse
from app.services.ai import analyze_meal_image, generate_chat_reply

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/chat", response_model=ChatResponse)
def chat(payload: ChatRequest, user=Depends(get_current_user)):
    reply = generate_chat_reply(payload.message, payload.context)
    return ChatResponse(reply=reply)


@router.post("/meal-scan", response_model=MealScanResponse)
async def meal_scan(image: UploadFile = File(...), user=Depends(get_current_user)):
    image_bytes = await image.read()
    analysis = analyze_meal_image(image_bytes)

    items = analysis.get("items", [])
    totals = analysis.get("totals", {})

    return MealScanResponse(
        items=items,
        total_calories=totals.get("calories", 0),
        total_protein=totals.get("protein", 0),
        total_carbs=totals.get("carbs", 0),
        total_fats=totals.get("fats", 0),
    )
