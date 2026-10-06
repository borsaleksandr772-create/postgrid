from .base import Publisher

class XPublisher(Publisher):
    async def publish(self, post: dict) -> dict:
        raise NotImplementedError("Connect OAuth + official X publishing API in phase 2")
