package xyz.nanian.owl.pitaya.constant;

/** Order topology owned by the inactive shopping module. */
public final class OrderMqConstants {
    private OrderMqConstants() {}
    public static final String ORDER_QUEUE = "order_queue";
    public static final String ORDER_EXCHANGE = "order_exchange";
    public static final String ORDER_ROUTING_KEY = "order_routing_key";
}
