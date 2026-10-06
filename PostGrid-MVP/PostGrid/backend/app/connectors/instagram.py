from .base import Publisher

class InstagramPublisher(Publisher):
    async def publish(self, post: dict) -> dict:
        raise NotImplementedError("Connect OAuth + official Instagram publishing API in phase 2")
