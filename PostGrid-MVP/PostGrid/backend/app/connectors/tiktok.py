from .base import Publisher

class TiktokPublisher(Publisher):
    async def publish(self, post: dict) -> dict:
        raise NotImplementedError("Connect OAuth + official Tiktok publishing API in phase 2")
